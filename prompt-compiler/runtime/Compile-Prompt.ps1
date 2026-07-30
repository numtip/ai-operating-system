<#
.SYNOPSIS
  AI-OS Prompt Compiler Runtime (v1.3) — no LLM, no network.
.DESCRIPTION
  Compiles Project + Goal + Model Profile + Constraints into:
    Head Agent prompt, Subagent task prompts, Context Manifest, Metrics.
  Dot-source this file or call Invoke-PromptCompile. Paths are repo-relative.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CompilerVersion = '1.3.0'
$script:CompilerSchemaVersion = '1.0'

# ---------------------------------------------------------------------------
# Path / IO helpers
# ---------------------------------------------------------------------------

function Get-RepoRoot {
    param([string]$ExplicitRoot)
    if ($ExplicitRoot) {
        $p = Resolve-Path -LiteralPath $ExplicitRoot
        return [string]$p
    }
    # runtime/ is under prompt-compiler/; repo root is parent of prompt-compiler
    $here = $PSScriptRoot
    if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $candidate = Resolve-Path (Join-Path $here '..\..')
    return [string]$candidate
}

function ConvertTo-RepoRelative {
    param(
        [Parameter(Mandatory)][string]$FullPath,
        [Parameter(Mandatory)][string]$RepoRoot
    )
    $full = [System.IO.Path]::GetFullPath($FullPath)
    $root = [System.IO.Path]::GetFullPath($RepoRoot)
    if (-not $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }
    $rel = $full.Substring($root.Length).TrimStart('\', '/')
    return ($rel -replace '\\', '/')
}

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory)][string]$RelPath,
        [Parameter(Mandatory)][string]$RepoRoot
    )
    $norm = ($RelPath -replace '\\', '/').TrimStart('/')
    if ($norm -match '\.\.|^\s*$' -or $norm.Contains(':')) {
        throw "Unsafe path rejected: $RelPath"
    }
    $full = Join-Path $RepoRoot ($norm -replace '/', [IO.Path]::DirectorySeparatorChar)
    $resolved = [System.IO.Path]::GetFullPath($full)
    $root = [System.IO.Path]::GetFullPath($RepoRoot)
    if (-not $resolved.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes repo root: $RelPath"
    }
    return $resolved
}

function Test-RepoPathExists {
    param(
        [Parameter(Mandatory)][string]$RelPath,
        [Parameter(Mandatory)][string]$RepoRoot,
        [ValidateSet('Any', 'Leaf', 'Container')][string]$PathType = 'Any'
    )
    try {
        $full = Resolve-RepoPath -RelPath $RelPath -RepoRoot $RepoRoot
    }
    catch { return $false }
    switch ($PathType) {
        'Leaf' { return Test-Path -LiteralPath $full -PathType Leaf }
        'Container' { return Test-Path -LiteralPath $full -PathType Container }
        default { return Test-Path -LiteralPath $full }
    }
}

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$FullPath)
    $raw = [System.IO.File]::ReadAllText($FullPath)
    return ($raw | ConvertFrom-Json)
}

function Get-StableJson {
    param($Object)
    # Deterministic-ish JSON: depth fixed; PS ConvertTo-Json is stable for ordered/hashtables
    return ($Object | ConvertTo-Json -Depth 12 -Compress)
}

function Get-Sha256Hex {
    param([AllowEmptyString()][string]$Text = '')
    if ($null -eq $Text) { $Text = '' }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally { $sha.Dispose() }
    return ([System.BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
}

function Get-EstimatedTokens {
    param([AllowEmptyString()][string]$Text = '')
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    return [int][Math]::Ceiling($Text.Length / 4.0)
}

# ---------------------------------------------------------------------------
# Task normalization
# ---------------------------------------------------------------------------

function Normalize-CompilerInput {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Goal,
        [Parameter(Mandatory)][string]$ModelProfile,
        [string[]]$Constraints = @(),
        [Parameter(Mandatory)][ValidateSet('json', 'markdown', 'both')][string]$OutputMode
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    $project = ($Project | ForEach-Object { $_.Trim() })
    $goal = if ($null -eq $Goal) { '' } else { $Goal.Trim() }
    $profile = ($ModelProfile | ForEach-Object { $_.Trim() })
    $mode = $OutputMode.ToLowerInvariant()

    $cList = New-Object System.Collections.Generic.List[string]
    foreach ($c in @($Constraints)) {
        if ($null -eq $c) { continue }
        $t = [string]$c
        foreach ($part in ($t -split ',')) {
            $p = $part.Trim()
            if ($p) { $cList.Add($p) | Out-Null }
        }
    }
    # stable unique order
    $unique = @($cList | Sort-Object -Unique)

    if ([string]::IsNullOrWhiteSpace($project)) {
        $errors.Add('missing_project: project is required') | Out-Null
    }
    if ([string]::IsNullOrWhiteSpace($goal)) {
        $errors.Add('empty_goal: goal must be a non-empty string') | Out-Null
    }
    if ([string]::IsNullOrWhiteSpace($profile)) {
        $errors.Add('missing_model_profile: model_profile is required') | Out-Null
    }

    # Conflicting constraints
    $joined = ($unique -join ' ').ToLowerInvariant()
    $hasReadOnly = $false
    $hasWrite = $false
    foreach ($u in $unique) {
        $l = $u.ToLowerInvariant()
        if ($l -match 'read[- ]?only|no[- ]write|forbid.*write|without modifying|do not modify') {
            $hasReadOnly = $true
        }
        if ($l -match 'allow[- ]write|must write|write required|mutate|edit files') {
            $hasWrite = $true
        }
    }
    if ($hasReadOnly -and $hasWrite) {
        $errors.Add('conflicting_constraints: read-only and write-required constraints cannot both apply') | Out-Null
    }

    # Infer audit/read-only from goal if not stated
    $goalLower = $goal.ToLowerInvariant()
    $inferredReadOnly = $false
    if ($goalLower -match 'audit|inspect|readiness|without modifying|identify blocking') {
        $inferredReadOnly = $true
    }

    return [ordered]@{
        project            = $project
        goal               = $goal
        model_profile      = $profile
        constraints        = $unique
        output_mode        = $mode
        inferred_read_only = $inferredReadOnly
        errors             = @($errors)
        warnings           = @($warnings)
    }
}

# ---------------------------------------------------------------------------
# Project adapter lookup
# ---------------------------------------------------------------------------

function Resolve-ProjectFromIndex {
    param(
        [Parameter(Mandatory)]$Entries,
        [Parameter(Mandatory)][string]$Name
    )
    $nameLower = $Name.Trim().ToLowerInvariant()

    foreach ($entry in @($Entries)) {
        if ($null -eq $entry) { continue }
        $id = [string]$entry.id
        if ($id -and ($id.ToLowerInvariant() -eq $nameLower -or $id.ToLowerInvariant() -eq "project-$nameLower")) {
            return @{ Entry = $entry; MatchedBy = 'id' }
        }
    }
    foreach ($entry in @($Entries)) {
        if ($null -eq $entry) { continue }
        $path = ([string]$entry.path) -replace '\\', '/'
        if (-not $path) { continue }
        $seg = ($path.TrimEnd('/') -split '/')[-1]
        if ($seg -and $seg.ToLowerInvariant() -eq $nameLower) {
            return @{ Entry = $entry; MatchedBy = 'path' }
        }
    }
    foreach ($entry in @($Entries)) {
        if ($null -eq $entry) { continue }
        $title = [string]$entry.title
        if ($title -and $title.ToLowerInvariant() -eq $nameLower) {
            return @{ Entry = $entry; MatchedBy = 'title' }
        }
    }
    return $null
}

function Parse-AdapterTableValue {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Field
    )
    # Match markdown table row: | field | value |
    $pattern = '(?im)^\|\s*' + [regex]::Escape($Field) + '\s*\|\s*([^|]+)\|'
    $m = [regex]::Match($Text, $pattern)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $null
}

function Get-AdapterCanonicalDocs {
    param([Parameter(Mandatory)][string]$AdapterText)
    $docs = @()
    $inSection = $false
    foreach ($line in ($AdapterText -split "`r?`n")) {
        if ($line -match '^##\s+4\.\s+Canonical') { $inSection = $true; continue }
        if ($inSection -and $line -match '^##\s+') { break }
        if (-not $inSection) { continue }
        if ($line -notmatch '^\|') { continue }
        if ($line -match '^\|\s*role\s*\|') { continue }
        if ($line -match '^\|\s*-+') { continue }
        $cells = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 3) { continue }
        $role = [string]$cells[0]
        $path = [string]$cells[1]
        $reqRaw = ([string]$cells[2]).ToLowerInvariant()
        if ($role -eq 'role' -or $path -eq 'path' -or [string]::IsNullOrWhiteSpace($path)) { continue }
        $required = ($reqRaw -eq 'true' -or $reqRaw -eq 'yes')
        $docs += ,([pscustomobject]@{
                role     = $role
                path     = $path
                required = [bool]$required
            })
    }
    return $docs
}

function Get-ProjectAdapter {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$RepoRoot
    )
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $indexHits = 0

    $indexRel = '12_Indexes/project_index.json'
    $indexFull = Resolve-RepoPath -RelPath $indexRel -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $indexFull -PathType Leaf)) {
        $errors.Add("broken_canonical_reference: missing $indexRel") | Out-Null
        return [ordered]@{
            ok = $false; errors = @($errors); warnings = @($warnings)
            index_hits = 0; project = $null
        }
    }

    $doc = Read-JsonFile -FullPath $indexFull
    $entries = @()
    if ($doc.PSObject.Properties.Name -contains 'entries') { $entries = @($doc.entries) }
    $indexHits++

    $match = Resolve-ProjectFromIndex -Entries $entries -Name $ProjectName
    $folder = $ProjectName
    $matchedBy = 'none'
    $indexEntry = $null

    if ($match) {
        $indexEntry = $match.Entry
        $matchedBy = $match.MatchedBy
        $path = ([string]$indexEntry.path) -replace '\\', '/'
        if ($path) { $folder = ($path.TrimEnd('/') -split '/')[-1] }
    }
    else {
        $warnings.Add("index_miss: project '$ProjectName' not in project_index; trying 01_Projects/$ProjectName/") | Out-Null
    }

    $projectRootRel = "01_Projects/$folder"
    $projectRootFull = Join-Path $RepoRoot ($projectRootRel -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $projectRootFull -PathType Container)) {
        $errors.Add("missing_project: project folder not found: $projectRootRel") | Out-Null
        return [ordered]@{
            ok = $false; errors = @($errors); warnings = @($warnings)
            index_hits = $indexHits; project = $null
        }
    }

    $adapterRel = "$projectRootRel/ADAPTER.md"
    $adapterFull = Join-Path $RepoRoot ($adapterRel -replace '/', [IO.Path]::DirectorySeparatorChar)
    $adapterPresent = Test-Path -LiteralPath $adapterFull -PathType Leaf
    $adapterText = $null
    $meta = [ordered]@{
        project_id      = $folder
        display_name    = $folder
        location_kind   = 'unknown'
        remote_url      = $null
        local_path      = $null
        vault_path      = $null
        memory_path     = $null
        status          = $null
        adapter_version = $null
    }
    $canonical = @()

    if ($adapterPresent) {
        $adapterText = [System.IO.File]::ReadAllText($adapterFull)
        $parsedProjectId = Parse-AdapterTableValue -Text $adapterText -Field 'project_id'
        if ($parsedProjectId) { $meta.project_id = $parsedProjectId }
        $dn = Parse-AdapterTableValue -Text $adapterText -Field 'display_name'
        if ($dn) { $meta.display_name = $dn }
        $lk = Parse-AdapterTableValue -Text $adapterText -Field 'location_kind'
        if ($lk) { $meta.location_kind = $lk }
        $ru = Parse-AdapterTableValue -Text $adapterText -Field 'remote_url'
        if ($ru) { $meta.remote_url = $ru }
        $lp = Parse-AdapterTableValue -Text $adapterText -Field 'local_path'
        if ($lp) { $meta.local_path = $lp }
        $vp = Parse-AdapterTableValue -Text $adapterText -Field 'vault_path'
        if ($vp) { $meta.vault_path = $vp }
        $mp = Parse-AdapterTableValue -Text $adapterText -Field 'memory_path'
        if ($mp) { $meta.memory_path = $mp }
        $st = Parse-AdapterTableValue -Text $adapterText -Field 'status'
        if ($st) { $meta.status = $st }
        $av = Parse-AdapterTableValue -Text $adapterText -Field 'adapter_version'
        if ($av) { $meta.adapter_version = $av }
        $canonical = Get-AdapterCanonicalDocs -AdapterText $adapterText
    }
    else {
        $warnings.Add("optional_missing_context: no ADAPTER.md at $adapterRel") | Out-Null
    }

    return [ordered]@{
        ok              = ($errors.Count -eq 0)
        errors          = @($errors)
        warnings        = @($warnings)
        index_hits      = $indexHits
        matched_by      = $matchedBy
        project_root    = $projectRootRel
        adapter_path    = $(if ($adapterPresent) { $adapterRel } else { $null })
        adapter_present = $adapterPresent
        meta            = $meta
        canonical_docs  = $canonical
        index_entry     = $indexEntry
    }
}

# ---------------------------------------------------------------------------
# Model profile selection
# ---------------------------------------------------------------------------

function Get-ModelProfile {
    param(
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)][string]$RepoRoot
    )
    $errors = New-Object System.Collections.Generic.List[string]
    $id = $ProfileId.Trim()
    $rel = "prompt-compiler/profiles/$id.json"
    try {
        $full = Resolve-RepoPath -RelPath $rel -RepoRoot $RepoRoot
    }
    catch {
        $errors.Add("unknown_model_profile: unsafe profile id '$id'") | Out-Null
        return [ordered]@{ ok = $false; errors = @($errors); profile = $null; path = $rel }
    }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        $errors.Add("unknown_model_profile: profile not found: $id") | Out-Null
        return [ordered]@{ ok = $false; errors = @($errors); profile = $null; path = $rel }
    }
    $profile = Read-JsonFile -FullPath $full
    if (-not $profile.id) {
        $errors.Add("invalid_model_profile: missing id in $rel") | Out-Null
        return [ordered]@{ ok = $false; errors = @($errors); profile = $null; path = $rel }
    }
    if ([string]$profile.id -ne $id) {
        $errors.Add("invalid_model_profile: id mismatch file=$id json=$($profile.id)") | Out-Null
        return [ordered]@{ ok = $false; errors = @($errors); profile = $null; path = $rel }
    }
    return [ordered]@{ ok = $true; errors = @(); profile = $profile; path = $rel }
}

# ---------------------------------------------------------------------------
# Context selection (references only)
# ---------------------------------------------------------------------------

function Select-CompilerContext {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)]$Normalized,
        [Parameter(Mandatory)]$ProjectInfo,
        [Parameter(Mandatory)]$ProfileInfo
    )
    $warnings = New-Object System.Collections.Generic.List[string]
    $errors = New-Object System.Collections.Generic.List[string]
    $selected = New-Object System.Collections.Generic.List[object]
    $indexHits = 0
    $goalTokens = @($Normalized.goal.ToLowerInvariant() -split '\W+' | Where-Object { $_.Length -ge 4 } | Sort-Object -Unique)

    function Add-Ref {
        param(
            [string]$Path,
            [string]$Source,
            [string]$Reason,
            [bool]$Required = $false
        )
        if ([string]::IsNullOrWhiteSpace($Path)) { return }
        $p = ($Path -replace '\\', '/').Trim()
        # Never emit absolute machine paths in selected context for external roots
        if ($p -match '^[A-Za-z]:' -or $p.StartsWith('\\\\')) {
            $warnings.Add("skipped_absolute_path: $p (use remote_url / project root ref)") | Out-Null
            return
        }
        foreach ($existing in $selected) {
            if ($existing.path -eq $p) { return }
        }
        $exists = $false
        if ($p -notmatch '^external:') {
            $exists = Test-RepoPathExists -RelPath $p -RepoRoot $RepoRoot -PathType 'Any'
            if (-not $exists) {
                if ($Required) {
                    $errors.Add("broken_canonical_reference: required path missing: $p") | Out-Null
                }
                else {
                    $warnings.Add("optional_missing_context: $p") | Out-Null
                }
                return
            }
        }
        $selected.Add([ordered]@{
                path     = $p
                source   = $Source
                reason   = $Reason
                required = $Required
            }) | Out-Null
    }

    # Bootstrap minimum (references only)
    Add-Ref -Path '07_Memory/OPERATING_RULES.md' -Source 'bootstrap' -Reason 'operating_rules' -Required $true
    Add-Ref -Path '07_Memory/SYSTEM_MEMORY.md' -Source 'bootstrap' -Reason 'system_memory' -Required $true
    Add-Ref -Path '07_Memory/CURRENT_STATE.md' -Source 'bootstrap' -Reason 'current_state' -Required $true
    Add-Ref -Path '09_SOP/AGENT_BOOTSTRAP.md' -Source 'bootstrap' -Reason 'agent_bootstrap' -Required $false

    # Indexes (always reference; count hits)
    $indexFiles = @(
        '12_Indexes/project_index.json',
        '12_Indexes/knowledge_index.json',
        '12_Indexes/adr_index.json',
        '12_Indexes/skill_index.json'
    )
    foreach ($ix in $indexFiles) {
        if (Test-RepoPathExists -RelPath $ix -RepoRoot $RepoRoot -PathType 'Leaf') {
            $indexHits++
            Add-Ref -Path $ix -Source 'index' -Reason 'index_lookup' -Required ($ix -eq '12_Indexes/project_index.json')
        }
        else {
            if ($ix -eq '12_Indexes/project_index.json') {
                $errors.Add("broken_canonical_reference: missing $ix") | Out-Null
            }
            else {
                $warnings.Add("index_miss: missing $ix") | Out-Null
            }
        }
    }

    # Project adapter + entry
    if ($ProjectInfo.adapter_path) {
        Add-Ref -Path $ProjectInfo.adapter_path -Source 'adapter' -Reason 'project_adapter' -Required $true
    }
    $readmeRel = "$($ProjectInfo.project_root)/README.md"
    Add-Ref -Path $readmeRel -Source 'project' -Reason 'project_entry' -Required $false

    if ($ProjectInfo.meta.memory_path) {
        Add-Ref -Path $ProjectInfo.meta.memory_path -Source 'memory' -Reason 'project_memory' -Required $false
    }

    # External project pointer (no absolute path)
    if ($ProjectInfo.meta.location_kind -eq 'external') {
        if ($ProjectInfo.meta.remote_url) {
            Add-Ref -Path ("external:remote:" + $ProjectInfo.meta.remote_url) -Source 'adapter' -Reason 'external_remote' -Required $false
        }
        else {
            Add-Ref -Path ("external:project:" + $ProjectInfo.meta.project_id) -Source 'adapter' -Reason 'external_project' -Required $false
        }
        # Validate required external canonical docs when local_path available
        $localPath = $ProjectInfo.meta.local_path
        $localOk = $false
        if ($localPath -and (Test-Path -LiteralPath $localPath -PathType Container)) {
            $localOk = $true
        }
        elseif ($localPath) {
            $warnings.Add("external_root_unavailable: cannot verify external required docs") | Out-Null
        }
        foreach ($doc in @($ProjectInfo.canonical_docs)) {
            if (-not $doc.required) { continue }
            $cpath = [string]$doc.path
            if ($localOk) {
                $full = Join-Path $localPath ($cpath -replace '/', [IO.Path]::DirectorySeparatorChar)
                if (-not (Test-Path -LiteralPath $full)) {
                    $errors.Add("broken_canonical_reference: external required $($doc.role) missing: $cpath") | Out-Null
                }
                else {
                    Add-Ref -Path ("external:doc:" + $ProjectInfo.meta.project_id + '/' + ($cpath -replace '\\', '/')) -Source 'adapter-canonical' -Reason $doc.role -Required $true
                }
            }
            else {
                # Reference only; do not fail if external root not on this machine
                Add-Ref -Path ("external:doc:" + $ProjectInfo.meta.project_id + '/' + ($cpath -replace '\\', '/')) -Source 'adapter-canonical' -Reason ($doc.role + '_unverified') -Required $false
                $warnings.Add("optional_missing_context: external required doc not verified: $cpath") | Out-Null
            }
        }
    }
    elseif ($ProjectInfo.meta.location_kind -eq 'in_vault') {
        foreach ($doc in @($ProjectInfo.canonical_docs)) {
            $base = $ProjectInfo.meta.vault_path
            if (-not $base) { $base = $ProjectInfo.project_root }
            $base = ($base -replace '\\', '/').TrimEnd('/')
            $cpath = ($doc.path -replace '\\', '/')
            $rel = "$base/$cpath"
            Add-Ref -Path $rel -Source 'adapter-canonical' -Reason $doc.role -Required ([bool]$doc.required)
        }
    }

    # Keyword-select from knowledge + ADR indexes (bounded)
    $maxRefs = 10
    if ($ProfileInfo.profile -and $ProfileInfo.profile.context_limit_policy -and $ProfileInfo.profile.context_limit_policy.max_context_refs) {
        $maxRefs = [int]$ProfileInfo.profile.context_limit_policy.max_context_refs
    }

    $knowledgeRel = '12_Indexes/knowledge_index.json'
    if (Test-RepoPathExists -RelPath $knowledgeRel -RepoRoot $RepoRoot -PathType 'Leaf') {
        $kdoc = Read-JsonFile -FullPath (Resolve-RepoPath -RelPath $knowledgeRel -RepoRoot $RepoRoot)
        foreach ($entry in @($kdoc.entries)) {
            if ($selected.Count -ge $maxRefs) { break }
            $title = ([string]$entry.title).ToLowerInvariant()
            $tags = @($entry.tags | ForEach-Object { [string]$_.ToLowerInvariant() })
            $id = ([string]$entry.id).ToLowerInvariant()
            $hit = $false
            foreach ($tok in $goalTokens) {
                if ($title -match [regex]::Escape($tok) -or $id -match [regex]::Escape($tok) -or ($tags -contains $tok)) {
                    $hit = $true; break
                }
            }
            # Always keep high-value governance for audits
            if ($id -in @('operating-rules', 'system-memory', 'context-engine') ) { $hit = $true }
            if ($hit) {
                $indexHits++
                Add-Ref -Path ([string]$entry.path) -Source 'knowledge_index' -Reason 'goal_match' -Required $false
            }
        }
    }

    $adrRel = '12_Indexes/adr_index.json'
    if (Test-RepoPathExists -RelPath $adrRel -RepoRoot $RepoRoot -PathType 'Leaf') {
        $adoc = Read-JsonFile -FullPath (Resolve-RepoPath -RelPath $adrRel -RepoRoot $RepoRoot)
        $adrKeywords = @('adapter', 'bootstrap', 'prompt', 'compiler', 'context', 'index', 'local', 'hermes')
        foreach ($entry in @($adoc.entries)) {
            if ($selected.Count -ge $maxRefs + 4) { break }
            $title = ([string]$entry.title).ToLowerInvariant()
            $path = ([string]$entry.path).ToLowerInvariant()
            $hit = $false
            foreach ($kw in $adrKeywords) {
                if ($title -match $kw -or $path -match $kw) {
                    # only if goal also relates OR always for prompt/adapter related ADRs on compile tasks
                    if ($Normalized.goal.ToLowerInvariant() -match $kw -or $kw -in @('adapter', 'prompt', 'compiler', 'local')) {
                        $hit = $true; break
                    }
                }
            }
            if ($hit) {
                $indexHits++
                Add-Ref -Path ([string]$entry.path) -Source 'adr_index' -Reason 'goal_match' -Required $false
            }
        }
    }

    # Cap by profile max (preserve required first)
    $required = @($selected | Where-Object { $_.required })
    $optional = @($selected | Where-Object { -not $_.required })
    $capped = New-Object System.Collections.Generic.List[object]
    foreach ($r in $required) { $capped.Add($r) | Out-Null }
    foreach ($o in $optional) {
        if ($capped.Count -ge $maxRefs) { break }
        $capped.Add($o) | Out-Null
    }

    # Stable sort: required first, then path
    $ordered = @($capped | Sort-Object @{ Expression = { if ($_.required) { 0 } else { 1 } } }, @{ Expression = { $_.path } })

    $operatingRules = @(
        'Token reduction first',
        'Targeted reads only',
        'Index before file',
        'Memory before search',
        'No Hermes install',
        'No external model API calls',
        'No absolute machine-specific paths in generated prompts',
        'Head Agent owns integration; subagents stay bounded'
    )

    return [ordered]@{
        selected         = $ordered
        operating_rules  = $operatingRules
        index_hits       = $indexHits
        warnings         = @($warnings)
        errors           = @($errors)
        max_context_refs = $maxRefs
    }
}

# ---------------------------------------------------------------------------
# Subagent compiler
# ---------------------------------------------------------------------------

function New-CompilerSubagentPrompt {
    param(
        [string]$Id,
        [string]$Objective,
        [string[]]$Allowed,
        [string[]]$ForbiddenBase,
        [string[]]$ForbiddenExtra,
        [string]$Deliverable,
        [string[]]$Validation,
        [string]$ScopeMode,
        [string]$Verbosity
    )
    $allForbidden = @($ForbiddenBase + $ForbiddenExtra | Where-Object { $_ } | Sort-Object -Unique)
    $allowedLines = ($Allowed | ForEach-Object { "- $_" }) -join "`n"
    $forbiddenLines = ($allForbidden | ForEach-Object { "- $_" }) -join "`n"
    $validationLines = ($Validation | ForEach-Object { "- [ ] $_" }) -join "`n"
    $text = @"
## Subagent: $Id
## Assigned objective
$Objective

## Scope mode
$ScopeMode

## Allowed files or indexes
$allowedLines

## Forbidden scope
$forbiddenLines

## Expected deliverable
$Deliverable

## Validation requirements
$validationLines

## Output limit
- Verbosity: $Verbosity
- Max words: 250
- No nested lists

## Handoff format
Return ONLY:
- findings (bullets)
- blockers
- evidence paths (repo-relative or external: refs)
- residual risks
"@
    [pscustomobject]@{
        id          = $Id
        objective   = $Objective
        scope_mode  = $ScopeMode
        allowed     = @($Allowed)
        forbidden   = @($allForbidden)
        deliverable = $Deliverable
        prompt      = (($text -replace "`r`n", "`n").Trim() + "`n")
    }
}

function New-SubagentPrompts {
    param(
        [Parameter(Mandatory)]$Normalized,
        [Parameter(Mandatory)]$ProjectInfo,
        [Parameter(Mandatory)]$ProfileInfo,
        [Parameter(Mandatory)]$Context,
        [bool]$ReadOnly = $true
    )
    $projectId = [string]$ProjectInfo.meta.project_id
    $goalLower = $Normalized.goal.ToLowerInvariant()
    $prompts = @()

    $allowedBase = @(
        [string]$ProjectInfo.project_root
        '12_Indexes/'
        '07_Memory/OPERATING_RULES.md'
        '07_Memory/SYSTEM_MEMORY.md'
        '07_Memory/CURRENT_STATE.md'
    )
    if ($ProjectInfo.adapter_path) { $allowedBase += [string]$ProjectInfo.adapter_path }
    if ($ProjectInfo.meta.memory_path) { $allowedBase += [string]$ProjectInfo.meta.memory_path }

    $forbidden = @(
        'Do not modify external repositories'
        'Do not install Hermes'
        'Do not call external model APIs'
        'Do not push or tag'
        'Do not copy foreign project instructions into this project context'
    )
    if ($ReadOnly) {
        $forbidden += 'Write scope: none (read-only audit)'
    }

    $verbosity = 'short'
    if ($null -ne $ProfileInfo.profile) {
        $verbosity = [string]$ProfileInfo.profile.verbosity_limit
    }

    if ($goalLower -match 'inspect|publication|pipeline|blocking') {
        $prompts += New-CompilerSubagentPrompt -Id 'inspect-pipeline' `
            -Objective "Inspect publication/pipeline readiness signals for $projectId." `
            -Allowed ($allowedBase + @('03_Architecture/', '09_SOP/', '11_Templates/')) `
            -ForbiddenBase $forbidden `
            -ForbiddenExtra @('Do not load goffice2026 adapter or memory', 'Do not copy instructions from other projects') `
            -Deliverable 'Pipeline readiness notes + missing pieces' `
            -Validation @('Only this project context', 'Blocking issues labeled', 'No cross-project instruction leak') `
            -ScopeMode 'read-only' -Verbosity $verbosity

        $prompts += New-CompilerSubagentPrompt -Id 'inspect-blockers' `
            -Objective "List blocking issues preventing publication readiness for $projectId." `
            -Allowed ($allowedBase + @('12_Indexes/', '07_Memory/CURRENT_STATE.md')) `
            -ForbiddenBase $forbidden `
            -ForbiddenExtra @('Do not redesign architecture', 'Do not overlap inspect-pipeline deep architecture scan') `
            -Deliverable 'Ordered blocker list (P0/P1/P2)' `
            -Validation @('Each blocker has evidence path', 'No write actions proposed as completed', 'Handoff bounded') `
            -ScopeMode 'read-only' -Verbosity $verbosity
    }
    elseif ($goalLower -match 'audit|production readiness') {
        $prompts += New-CompilerSubagentPrompt -Id 'qa-structure' `
            -Objective "Audit structural readiness for project $projectId (layout, adapter, indexes)." `
            -Allowed ($allowedBase + @('03_Architecture/project-adapter/SPEC.md', 'scripts/')) `
            -ForbiddenBase $forbidden `
            -ForbiddenExtra @('Do not open unrelated project adapters', "Do not write under $($ProjectInfo.project_root) unless Head Agent expands scope") `
            -Deliverable 'Structure readiness findings with severity' `
            -Validation @('Only allowed paths read', 'No external write', 'Findings reference paths only') `
            -ScopeMode 'read-only' -Verbosity $verbosity

        $prompts += New-CompilerSubagentPrompt -Id 'qa-docs-canonical' `
            -Objective "Verify required canonical document references for $projectId without modifying sources." `
            -Allowed ($allowedBase + @('03_Architecture/project-adapter/SPEC.md')) `
            -ForbiddenBase $forbidden `
            -ForbiddenExtra @('Do not audit scripts/ (owned by qa-structure)', 'Do not invent missing docs content') `
            -Deliverable 'Canonical doc presence matrix + gaps' `
            -Validation @('Required vs optional distinguished', 'Broken refs listed', 'No absolute machine paths in handoff') `
            -ScopeMode 'read-only' -Verbosity $verbosity

        $prompts += New-CompilerSubagentPrompt -Id 'qa-risk-gates' `
            -Objective "Identify production-readiness risk gates and forbidden-action coverage for $projectId." `
            -Allowed ($allowedBase + @('04_ADR/', '07_Memory/DECISION_MEMORY.md', '03_Architecture/ROADMAP.md')) `
            -ForbiddenBase $forbidden `
            -ForbiddenExtra @('Do not re-check structure already owned by qa-structure', 'Do not re-validate doc matrix owned by qa-docs-canonical') `
            -Deliverable 'Risk gate list with pass/fail/unknown' `
            -Validation @('No overlap findings recycled from other subagents', 'External write permission = denied', 'Handoff uses Output format') `
            -ScopeMode 'read-only' -Verbosity $verbosity
    }
    else {
        $scopeMode = if ($ReadOnly) { 'read-only' } else { 'write' }
        $prompts += New-CompilerSubagentPrompt -Id 'task-research' `
            -Objective $Normalized.goal `
            -Allowed $allowedBase `
            -ForbiddenBase $forbidden `
            -ForbiddenExtra @('Stay within allowed paths') `
            -Deliverable 'Task research summary' `
            -Validation @('Scope respected', 'Output format matched') `
            -ScopeMode $scopeMode -Verbosity $verbosity
    }

    $decomp = ''
    if ($null -ne $ProfileInfo.profile) {
        $decomp = [string]$ProfileInfo.profile.task_decomposition
    }
    if ($decomp -match 'minimal-subagents|single-pass' -and $prompts.Count -gt 1) {
        $prompts = @($prompts[0])
    }

    return @($prompts)
}

# ---------------------------------------------------------------------------
# Head agent prompt compilation
# ---------------------------------------------------------------------------

function New-HeadAgentPrompt {
    param(
        [Parameter(Mandatory)]$Normalized,
        [Parameter(Mandatory)]$ProjectInfo,
        [Parameter(Mandatory)]$ProfileInfo,
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Subagents,
        [bool]$ReadOnly = $true
    )
    $projectId = $ProjectInfo.meta.project_id
    $display = $ProjectInfo.meta.display_name
    $profile = $ProfileInfo.profile

    $contextLines = @($Context.selected | ForEach-Object { "- $($_.path) ($($_.source)/$($_.reason))" })
    $constraintLines = New-Object System.Collections.Generic.List[string]
    foreach ($c in @($Normalized.constraints)) { $constraintLines.Add("- $c") | Out-Null }
    if ($ReadOnly) {
        $constraintLines.Add('- Read-only toward external repositories (no modify)') | Out-Null
    }
    $constraintLines.Add('- No Hermes install') | Out-Null
    $constraintLines.Add('- No external model API calls') | Out-Null
    $constraintLines.Add('- No absolute machine-specific paths in outputs') | Out-Null
    $constraintLines.Add('- Do not leak instructions from other projects') | Out-Null
    # unique stable
    $constraintLines = @($constraintLines | Sort-Object -Unique)

    $rules = @($Context.operating_rules | ForEach-Object { "- $_" })
    $subIds = @($Subagents | ForEach-Object { $_.id })
    $subList = if ($subIds.Count) { ($subIds | ForEach-Object { "- $_" }) -join "`n" } else { '- (none)' }

    $success = @(
        '- Goal outcome is answered with evidence paths'
        '- Subagent handoffs integrated without scope overlap'
        '- Forbidden actions not violated'
        '- Output matches Output Format exactly'
    )

    $forbiddenActions = @(
        '- Modify external repositories'
        '- Install Hermes or call model APIs'
        '- Push, tag, or publish without human approval'
        '- Invent project facts not supported by selected context'
        '- Use absolute machine-specific paths in deliverables'
    )
    if ($ReadOnly) {
        $forbiddenActions += '- Write to any path outside an explicitly expanded Head-owned write set (default: none)'
    }

    $outFmt = @"
Return ONLY:
1. Verdict (PASS | PASS_WITH_NOTES | FAIL)
2. Findings (bullets, severity-tagged)
3. Blockers
4. Evidence paths (repo-relative or external: refs)
5. Subagent integration summary
6. Residual risks
"@

    $profileLine = if ($profile) {
        "model_profile=$($profile.id); role_style=$($profile.role_style); verbosity=$($profile.verbosity_limit); decomposition=$($profile.task_decomposition)"
    }
    else { "model_profile=unknown" }

    $location = $ProjectInfo.meta.location_kind
    $remote = $ProjectInfo.meta.remote_url
    $projectBlock = "project_id=$projectId; display_name=$display; location_kind=$location"
    if ($remote) { $projectBlock += "; remote_url=$remote" }
    $projectBlock += "; adapter=$(if ($ProjectInfo.adapter_path) { $ProjectInfo.adapter_path } else { 'none' })"

    $prompt = @"
# Head Agent — Compiled Task

## Project
$projectBlock

## Goal
$($Normalized.goal)

## Model profile
$profileLine
tool_use: $(if ($profile) { $profile.tool_use_guidance } else { 'n/a' })

## Operating constraints
$($constraintLines -join "`n")

## Operating rules applied
$($rules -join "`n")

## Selected context (references only)
$($contextLines -join "`n")

## Success criteria
$($success -join "`n")

## Forbidden actions
$($forbiddenActions -join "`n")

## Subagents (Head integrates; no overlap unless stated)
$subList
Head responsibility: assign, collect handoffs, resolve conflicts, produce final verdict.

## Output format
$outFmt
"@

    return (($prompt -replace "`r`n", "`n").Trim() + "`n")
}

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

function Assert-CompiledPrompt {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)]$Normalized,
        [Parameter(Mandatory)]$ProjectInfo
    )
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        $errors.Add('validation: head_agent_prompt is empty') | Out-Null
        return [ordered]@{ errors = @($errors); warnings = @($warnings) }
    }

    $needles = @(
        @{ k = 'project'; r = '(?i)##\s*Project' },
        @{ k = 'goal'; r = '(?i)##\s*Goal' },
        @{ k = 'constraints'; r = '(?i)Operating constraints' },
        @{ k = 'context'; r = '(?i)Selected context' },
        @{ k = 'success'; r = '(?i)Success criteria' },
        @{ k = 'forbidden'; r = '(?i)Forbidden actions' },
        @{ k = 'output'; r = '(?i)Output format' }
    )
    foreach ($n in $needles) {
        if ($Prompt -notmatch $n.r) {
            $errors.Add("validation: missing section $($n.k)") | Out-Null
        }
    }

    if ($Prompt -notmatch [regex]::Escape($ProjectInfo.meta.project_id)) {
        $errors.Add('validation: project id not present in prompt') | Out-Null
    }
    if ($Prompt -notmatch [regex]::Escape($Normalized.goal)) {
        # goal may have regex special chars
        if ($Prompt.IndexOf($Normalized.goal, [StringComparison]::Ordinal) -lt 0) {
            $errors.Add('validation: exact goal not present in prompt') | Out-Null
        }
    }

    # Absolute path leakage (Windows drive or UNC) — fail
    # Allow URL schemes (https://) — only flag drive roots like C:\ or C:/foo (not ://).
    if ($Prompt -match '(?i)\b[A-Za-z]:\\') {
        $errors.Add('validation: absolute machine path detected in compiled prompt') | Out-Null
    }
    elseif ($Prompt -match '(?i)\b[A-Za-z]:/(?!/)') {
        $errors.Add('validation: absolute machine path detected in compiled prompt') | Out-Null
    }
    if ($Prompt -match '(?i)(?:^|[\s\"''(])\\\\[A-Za-z0-9._-]+\\') {
        $errors.Add('validation: UNC path detected in compiled prompt') | Out-Null
    }

    # Boundedness soft check
    $words = @($Prompt -split '\s+' | Where-Object { $_ })
    if ($words.Count -gt 800) {
        $warnings.Add("prompt_large: word_count=$($words.Count) exceeds soft bound 800") | Out-Null
    }

    return [ordered]@{ errors = @($errors); warnings = @($warnings) }
}

# ---------------------------------------------------------------------------
# Metrics + main entry
# ---------------------------------------------------------------------------

function Invoke-PromptCompile {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Goal,
        [Parameter(Mandatory)][string]$ModelProfile,
        [string[]]$Constraints = @(),
        [ValidateSet('json', 'markdown', 'both')][string]$OutputMode = 'both',
        [string]$RepoRoot = ''
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $root = Get-RepoRoot -ExplicitRoot $RepoRoot
    $allErrors = New-Object System.Collections.Generic.List[string]
    $allWarnings = New-Object System.Collections.Generic.List[string]

    $normalized = Normalize-CompilerInput -Project $Project -Goal $Goal -ModelProfile $ModelProfile -Constraints $Constraints -OutputMode $OutputMode
    foreach ($e in $normalized.errors) { $allErrors.Add($e) | Out-Null }
    foreach ($w in $normalized.warnings) { $allWarnings.Add($w) | Out-Null }

    $inputObj = [ordered]@{
        project       = $normalized.project
        goal          = $normalized.goal
        model_profile = $normalized.model_profile
        constraints   = @($normalized.constraints)
        output_mode   = $normalized.output_mode
    }
    $inputJson = Get-StableJson -Object $inputObj
    $inputSize = $inputJson.Length

    $projectInfo = $null
    $profileInfo = $null
    $context = $null
    $subagents = @()
    $headPrompt = ''
    $readOnly = $true

    if ($allErrors.Count -eq 0) {
        $projectInfo = Get-ProjectAdapter -ProjectName $normalized.project -RepoRoot $root
        foreach ($e in $projectInfo.errors) { $allErrors.Add($e) | Out-Null }
        foreach ($w in $projectInfo.warnings) { $allWarnings.Add($w) | Out-Null }
    }

    if ($allErrors.Count -eq 0) {
        $profileInfo = Get-ModelProfile -ProfileId $normalized.model_profile -RepoRoot $root
        foreach ($e in $profileInfo.errors) { $allErrors.Add($e) | Out-Null }
    }

    if ($allErrors.Count -eq 0) {
        # Determine read-only
        $readOnly = [bool]$normalized.inferred_read_only
        foreach ($c in $normalized.constraints) {
            $l = $c.ToLowerInvariant()
            if ($l -match 'read[- ]?only|no[- ]write|without modifying|do not modify') { $readOnly = $true }
            if ($l -match 'allow[- ]write|write required') { $readOnly = $false }
        }

        $context = Select-CompilerContext -RepoRoot $root -Normalized $normalized -ProjectInfo $projectInfo -ProfileInfo $profileInfo
        foreach ($e in $context.errors) { $allErrors.Add($e) | Out-Null }
        foreach ($w in $context.warnings) { $allWarnings.Add($w) | Out-Null }
    }

    if ($allErrors.Count -eq 0) {
        $subagents = New-SubagentPrompts -Normalized $normalized -ProjectInfo $projectInfo -ProfileInfo $profileInfo -Context $context -ReadOnly $readOnly
        $headPrompt = New-HeadAgentPrompt -Normalized $normalized -ProjectInfo $projectInfo -ProfileInfo $profileInfo -Context $context -Subagents $subagents -ReadOnly $readOnly
        $val = Assert-CompiledPrompt -Prompt $headPrompt -Normalized $normalized -ProjectInfo $projectInfo
        foreach ($e in $val.errors) { $allErrors.Add($e) | Out-Null }
        foreach ($w in $val.warnings) { $allWarnings.Add($w) | Out-Null }
    }

    $sw.Stop()
    $status = if ($allErrors.Count -gt 0) { 'error' } else { 'ok' }
    if ($status -eq 'error') {
        $headPrompt = ''
        $subagents = @()
    }

    $subTexts = @($subagents | ForEach-Object { $_.prompt })
    $compiledAll = $headPrompt + ($subTexts -join '')
    $compiledSize = $compiledAll.Length
    $estTokens = Get-EstimatedTokens -Text $compiledAll

    $contextPaths = @()
    $indexHits = 0
    $rulesApplied = @()
    if ($context) {
        $contextPaths = @($context.selected | ForEach-Object { $_.path })
        $indexHits = [int]$context.index_hits
        $rulesApplied = @($context.operating_rules)
    }
    elseif ($projectInfo -and ($projectInfo.PSObject.Properties.Name -contains 'index_hits' -or $projectInfo.Keys -contains 'index_hits')) {
        $indexHits = [int]$projectInfo.index_hits
    }

    # Deterministic hash: exclude duration and wall-clock
    $hashPayload = [ordered]@{
        status             = $status
        input              = $inputObj
        head_agent_prompt  = $headPrompt
        subagent_prompts   = @($subagents | ForEach-Object {
                [ordered]@{
                    id         = $_.id
                    objective  = $_.objective
                    scope_mode = $_.scope_mode
                    prompt     = $_.prompt
                }
            })
        context_paths      = @($contextPaths)
        operating_rules    = @($rulesApplied)
        errors             = @($allErrors | Sort-Object)
        warnings           = @($allWarnings | Sort-Object)
        model_profile      = $normalized.model_profile
        project            = $normalized.project
        compiler_version   = $script:CompilerVersion
        schema_version     = $script:CompilerSchemaVersion
    }
    $deterministicHash = Get-Sha256Hex -Text (Get-StableJson -Object $hashPayload)

    $result = [ordered]@{
        status              = $status
        errors              = @($allErrors)
        warnings            = @($allWarnings)
        input               = $inputObj
        project             = $(if ($projectInfo -and $projectInfo.ok -and $projectInfo.meta) {
                [ordered]@{
                    id              = $projectInfo.meta.project_id
                    display_name    = $projectInfo.meta.display_name
                    root            = $projectInfo.project_root
                    adapter         = $projectInfo.adapter_path
                    location_kind   = $projectInfo.meta.location_kind
                    remote_url      = $projectInfo.meta.remote_url
                    matched_by      = $projectInfo.matched_by
                }
            }
            else { $null })
        model_profile       = $(if ($profileInfo -and $profileInfo.ok -and $profileInfo.profile) {
                [ordered]@{
                    id                       = [string]$profileInfo.profile.id
                    display_name             = [string]$profileInfo.profile.display_name
                    role_style               = [string]$profileInfo.profile.role_style
                    task_decomposition       = [string]$profileInfo.profile.task_decomposition
                    expected_output_format   = [string]$profileInfo.profile.expected_output_format
                    verbosity_limit          = [string]$profileInfo.profile.verbosity_limit
                    tool_use_guidance        = [string]$profileInfo.profile.tool_use_guidance
                    path                     = $profileInfo.path
                }
            }
            else { [ordered]@{ id = $normalized.model_profile } })
        head_agent_prompt   = $headPrompt
        subagent_prompts    = @($subagents)
        context_manifest    = [ordered]@{
            selected            = $(if ($context) { @($context.selected) } else { @() })
            operating_rules     = $rulesApplied
            context_files       = $contextPaths
            index_hits          = $indexHits
        }
        metrics             = [ordered]@{
            input_size_chars         = $inputSize
            compiled_prompt_size_chars = $compiledSize
            estimated_tokens         = $estTokens
            context_files_selected   = $contextPaths.Count
            index_hits               = $indexHits
            warnings                 = $allWarnings.Count
            subagent_count           = @($subagents).Count
            compilation_duration_ms  = [int]$sw.ElapsedMilliseconds
            deterministic_hash       = $deterministicHash
        }
        compiler_metadata   = [ordered]@{
            version         = $script:CompilerVersion
            schema_version  = $script:CompilerSchemaVersion
            repo_root_mode  = 'caller-relative'
            output_mode     = $normalized.output_mode
            read_only       = $readOnly
        }
    }

    return $result
}

function Format-CompilerMarkdown {
    param([Parameter(Mandatory)]$Result)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# Prompt Compiler Result')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("**Status:** $($Result.status)")
    [void]$sb.AppendLine("**Hash:** $($Result.metrics.deterministic_hash)")
    [void]$sb.AppendLine()
    if ($Result.errors -and @($Result.errors).Count -gt 0) {
        [void]$sb.AppendLine('## Errors')
        foreach ($e in @($Result.errors)) { [void]$sb.AppendLine("- $e") }
        [void]$sb.AppendLine()
    }
    if ($Result.warnings -and @($Result.warnings).Count -gt 0) {
        [void]$sb.AppendLine('## Warnings')
        foreach ($w in @($Result.warnings)) { [void]$sb.AppendLine("- $w") }
        [void]$sb.AppendLine()
    }
    if ($Result.status -eq 'ok') {
        [void]$sb.AppendLine('## Head Agent Prompt')
        [void]$sb.AppendLine()
        [void]$sb.AppendLine('```text')
        [void]$sb.AppendLine($Result.head_agent_prompt.TrimEnd())
        [void]$sb.AppendLine('```')
        [void]$sb.AppendLine()
        [void]$sb.AppendLine('## Subagent Prompts')
        foreach ($s in @($Result.subagent_prompts)) {
            [void]$sb.AppendLine()
            [void]$sb.AppendLine("### $($s.id)")
            [void]$sb.AppendLine()
            [void]$sb.AppendLine('```text')
            [void]$sb.AppendLine($s.prompt.TrimEnd())
            [void]$sb.AppendLine('```')
        }
        [void]$sb.AppendLine()
        [void]$sb.AppendLine('## Context Manifest')
        foreach ($c in @($Result.context_manifest.selected)) {
            $line = '- `{0}` — {1}/{2}' -f $c.path, $c.source, $c.reason
            [void]$sb.AppendLine($line)
        }
    }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('## Metrics')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('| Metric | Value |')
    [void]$sb.AppendLine('|--------|-------|')
    [void]$sb.AppendLine("| input_size_chars | $($Result.metrics.input_size_chars) |")
    [void]$sb.AppendLine("| compiled_prompt_size_chars | $($Result.metrics.compiled_prompt_size_chars) |")
    [void]$sb.AppendLine("| estimated_tokens | $($Result.metrics.estimated_tokens) |")
    [void]$sb.AppendLine("| context_files_selected | $($Result.metrics.context_files_selected) |")
    [void]$sb.AppendLine("| index_hits | $($Result.metrics.index_hits) |")
    [void]$sb.AppendLine("| warnings | $($Result.metrics.warnings) |")
    [void]$sb.AppendLine("| subagent_count | $($Result.metrics.subagent_count) |")
    [void]$sb.AppendLine("| compilation_duration_ms | $($Result.metrics.compilation_duration_ms) |")
    [void]$sb.AppendLine("| deterministic_hash | $($Result.metrics.deterministic_hash) |")
    return ($sb.ToString() -replace "`r`n", "`n")
}

# Export markers for hosts that care
$script:PromptCompilerLoaded = $true
