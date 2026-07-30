<#
.SYNOPSIS
  Deterministic bootstrap-runtime dry-run for a named project (no LLM).
.DESCRIPTION
  Stdlib PowerShell only. Implements AI-OS bootstrap-runtime SPEC steps 1-4:
    1) Read indexes  2) Locate canonical files  3) Plan minimum context  4) Emit summary
  Reads 12_Indexes/project_index.json and 01_Projects/<name>/ADAPTER.md if present.
  Counts files it would read; does not call LLMs; does not modify external trees.
  Writes 01_Projects/<name>/last-bootstrap-simulation.md when adapter exists;
  otherwise stdout only. Never writes under 06_Research/pilots/.
  Run from repo root:
    pwsh -File scripts/simulate-bootstrap.ps1 -ProjectName <name>
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/simulate-bootstrap.ps1 -ProjectName <name>
  Exit 0 on completed simulation (including not_found/degraded); 1 on hard block (missing index).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName
)

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$SchemaVersion = '1.2'
$GeneratedAt = (Get-Date).ToString('o')

function Get-RelPath {
    param([Parameter(Mandatory)][string]$FullPath)
    $full = [System.IO.Path]::GetFullPath($FullPath)
    $rootFull = [System.IO.Path]::GetFullPath([string]$Root)
    if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }
    $rel = $full.Substring($rootFull.Length).TrimStart('\', '/')
    return ($rel -replace '\\', '/')
}

function Test-RepoFile {
    param([Parameter(Mandatory)][string]$RelPath)
    $full = Join-Path $Root ($RelPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    return (Test-Path -LiteralPath $full -PathType Leaf)
}

function Resolve-ProjectEntry {
    param(
        [Parameter(Mandatory)]$Entries,
        [Parameter(Mandatory)][string]$Name
    )
    $nameNorm = $Name.Trim()
    $nameLower = $nameNorm.ToLowerInvariant()

    foreach ($entry in @($Entries)) {
        if ($null -eq $entry) { continue }
        $id = [string]$entry.id
        if ($id -and $id.ToLowerInvariant() -eq $nameLower) {
            return @{ Entry = $entry; MatchedBy = 'id' }
        }
        if ($id -and $id.ToLowerInvariant() -eq ("project-$nameLower")) {
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

# --- Step 1: Read indexes ---
$indexRel = '12_Indexes/project_index.json'
$indexFull = Join-Path $Root ($indexRel -replace '/', [IO.Path]::DirectorySeparatorChar)
$blockers = New-Object System.Collections.Generic.List[object]
$wouldRead = New-Object System.Collections.Generic.List[string]
$minContext = New-Object System.Collections.Generic.List[object]

$wouldRead.Add($indexRel) | Out-Null

$status = 'ready'
$resolvedId = $null
$projectRoot = $null
$adapterPresent = $false
$indexHit = $false
$matchedBy = 'none'
$filesRead = 0
$doc = $null

if (-not (Test-Path -LiteralPath $indexFull -PathType Leaf)) {
    $status = 'blocked'
    $blockers.Add([ordered]@{ code = 'missing_index'; message = "Missing $indexRel" }) | Out-Null
}
else {
    try {
        $raw = [System.IO.File]::ReadAllText($indexFull)
        $doc = $raw | ConvertFrom-Json
        $filesRead++
    }
    catch {
        $status = 'blocked'
        $blockers.Add([ordered]@{ code = 'missing_index'; message = "Unparseable $indexRel : $($_.Exception.Message)" }) | Out-Null
    }
}

# --- Step 2: Locate canonical files ---
if ($status -ne 'blocked' -and $null -ne $doc) {
    $entries = @()
    if ($doc.PSObject.Properties.Name -contains 'entries') {
        $entries = @($doc.entries)
    }

    $hit = Resolve-ProjectEntry -Entries $entries -Name $ProjectName
    if ($null -ne $hit) {
        $indexHit = $true
        $matchedBy = [string]$hit.MatchedBy
        $resolvedId = [string]$hit.Entry.id
        $path = ([string]$hit.Entry.path) -replace '\\', '/'
        if ($path -and -not $path.EndsWith('/')) { $path = "$path/" }
        $projectRoot = $path
    }
    else {
        $fallbackRel = "01_Projects/$ProjectName"
        $fallbackFull = Join-Path $Root ($fallbackRel -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $fallbackFull -PathType Container) {
            $projectRoot = "01_Projects/$ProjectName/"
            $matchedBy = 'folder_fallback'
            $indexHit = $false
        }
        else {
            $status = 'not_found'
            $matchedBy = 'none'
            $blockers.Add([ordered]@{ code = 'project_not_found'; message = "No index or folder match for '$ProjectName'" }) | Out-Null
        }
    }
}

$adapterRel = $null
$readmeRel = $null
if ($projectRoot) {
    $adapterRel = ($projectRoot.TrimEnd('/') + '/ADAPTER.md') -replace '\\', '/'
    $readmeRel = ($projectRoot.TrimEnd('/') + '/README.md') -replace '\\', '/'
    $adapterFull = Join-Path $Root ($adapterRel -replace '/', [IO.Path]::DirectorySeparatorChar)
    $adapterPresent = Test-Path -LiteralPath $adapterFull -PathType Leaf
}

# --- Step 3: Minimum context (skip on blocked / not_found) ---
$externalAdapter = $false
if ($status -ne 'blocked' -and $status -ne 'not_found') {
    $plan = @(
        @{ Order = 1; Rel = '07_Memory/SYSTEM_MEMORY.md'; Required = $true; Kind = 'memory' }
        @{ Order = 2; Rel = '07_Memory/CURRENT_STATE.md'; Required = $true; Kind = 'memory' }
    )
    if ($adapterRel) {
        $plan += @{ Order = 3; Rel = $adapterRel; Required = $false; Kind = 'adapter' }
    }
    if ($readmeRel) {
        $plan += @{ Order = 4; Rel = $readmeRel; Required = $false; Kind = 'readme' }
    }

    foreach ($item in $plan) {
        $rel = [string]$item.Rel
        $wouldRead.Add($rel) | Out-Null
        $exists = Test-RepoFile -RelPath $rel
        $state = 'would_read'
        if (-not $exists) {
            $state = 'missing'
            if ($item.Required) {
                if ($status -eq 'ready' -or $status -eq 'ready_local_only') { $status = 'degraded' }
                $code = if ($rel -like '*SYSTEM_MEMORY*') { 'missing_system_memory' } else { 'missing_current_state' }
                $blockers.Add([ordered]@{ code = $code; message = "Missing required file $rel" }) | Out-Null
            }
            elseif ($item.Kind -eq 'adapter' -or $item.Kind -eq 'readme') {
                $state = 'skipped'
            }
        }
        else {
            if ($item.Kind -eq 'memory' -or $item.Kind -eq 'adapter') {
                $full = Join-Path $Root ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)
                try {
                    $null = [System.IO.File]::ReadAllText($full)
                    $filesRead++
                    $state = 'read'
                    if ($item.Kind -eq 'adapter') {
                        $lines = Get-Content -LiteralPath $full -TotalCount 40 -ErrorAction SilentlyContinue
                        foreach ($line in $lines) {
                            if ($line -match '(?i)(external_root|external_path|repo_path)\s*[:=]\s*(.+)$') {
                                $target = $Matches[2].Trim().Trim('"').Trim("'")
                                if ($target -match '^[A-Za-z]:\\' -or $target -match '^/') {
                                    $inRepo = $null -ne (Get-RelPath -FullPath $target)
                                    if (-not $inRepo) { $externalAdapter = $true }
                                }
                                elseif ($target -and
                                    -not (Test-Path -LiteralPath (Join-Path $Root ($target -replace '/', [IO.Path]::DirectorySeparatorChar)))) {
                                    if ($target -notmatch '(?i)^01_Projects[/\\]') { $externalAdapter = $true }
                                }
                            }
                        }
                    }
                }
                catch {
                    $state = 'missing'
                }
            }
            else {
                $state = 'would_read'
            }
        }
        $minContext.Add([ordered]@{
                order = [int]$item.Order
                path  = $rel
                state = $state
            }) | Out-Null
    }

    if ($externalAdapter) {
        if ($status -eq 'ready') { $status = 'ready_local_only' }
        $blockers.Add([ordered]@{
                code    = 'external_adapter_target'
                message = 'ADAPTER.md references a path outside the vault; not followed'
            }) | Out-Null
    }
}

$uniqueWould = @($wouldRead | Select-Object -Unique)
$filesWouldRead = $uniqueWould.Count

# --- Step 4: Produce bootstrap summary ---
function Format-BlockersMarkdown {
    if ($blockers.Count -eq 0) { return '- (none)' }
    ($blockers | ForEach-Object { "- $($_.code): $($_.message)" }) -join "`n"
}

function Format-MinContextTable {
    if ($minContext.Count -eq 0) {
        return '| order | path | state |' + "`n" + '|-------|------|-------|' + "`n" + '| — | (none; stopped early) | — |'
    }
    $rows = @(
        '| order | path | state |'
        '|-------|------|-------|'
    )
    foreach ($row in $minContext) {
        $rows += ("| {0} | `{1}` | {2} |" -f $row.order, $row.path, $row.state)
    }
    return ($rows -join "`n")
}

$orderedReadsMd = @()
if ($status -ne 'blocked' -and $status -ne 'not_found') {
    $orderNum = 1
    $orderedReadsMd += ("{0}. ``12_Indexes/project_index.json``" -f $orderNum)
    $orderNum++
    foreach ($row in $minContext) {
        if ($row.state -eq 'skipped') { continue }
        $orderedReadsMd += ("{0}. ``{1}``" -f $orderNum, $row.path)
        $orderNum++
    }
    if ($projectRoot) {
        $orderedReadsMd += ("{0}. ``07_Memory/DECISION_MEMORY.md`` *(deferred unless needed)*" -f $orderNum)
    }
}

$resolvedDisplay = if ($resolvedId) { $resolvedId } else { '(none)' }
$rootDisplay = if ($projectRoot) { $projectRoot } else { '(none)' }
$adapterFlag = $adapterPresent.ToString().ToLowerInvariant()
$indexHitFlag = $indexHit.ToString().ToLowerInvariant()
$minTable = Format-MinContextTable
$blockerMd = Format-BlockersMarkdown
$orderedMd = if ($orderedReadsMd.Count -eq 0) { '- (empty)' } else { $orderedReadsMd -join "`n" }

$summary = @"
# Bootstrap Summary: $ProjectName

- **status:** $status
- **resolved_id:** $resolvedDisplay
- **project_root:** $rootDisplay
- **adapter_present:** $adapterFlag
- **files_would_read:** $filesWouldRead
- **files_read:** $filesRead
- **generated_at:** $GeneratedAt
- **schema_version:** $SchemaVersion

## Match
- index_hit: $indexHitFlag
- matched_by: $matchedBy

## Minimum context
$minTable

## Blockers
$blockerMd

## Ordered context package (next reads)
$orderedMd

## Constraints
- Index before file; memory before search
- No LLM; no Hermes; no DB
- External adapter targets not followed
- Simulation write forbidden under ``06_Research/pilots/``
"@

Write-Output $summary

if ($adapterPresent -and $projectRoot) {
    $outRel = ($projectRoot.TrimEnd('/') + '/last-bootstrap-simulation.md') -replace '\\', '/'
    if ($outRel -match '^01_Projects/[^/]+/last-bootstrap-simulation\.md$') {
        $outFull = Join-Path $Root ($outRel -replace '/', [IO.Path]::DirectorySeparatorChar)
        $outDir = Split-Path -Parent $outFull
        if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
            Write-Host "WARN  project folder missing; skipping write: $outRel"
        }
        else {
            $utf8 = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($outFull, ($summary.TrimEnd() + "`n"), $utf8)
            Write-Host ""
            Write-Host "Wrote $outRel"
        }
    }
    else {
        Write-Host "WARN  refused write outside project folder: $outRel"
    }
}
else {
    Write-Host ""
    Write-Host "stdout only (adapter absent or project unresolved); no file written"
}

if ($status -eq 'blocked') {
    exit 1
}
exit 0
