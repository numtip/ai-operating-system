<#
.SYNOPSIS
  AI-OS v1.5 Bootstrap Gate checker. Stdlib PowerShell only (no LLM / Hermes / DB).

.DESCRIPTION
  Validates the pre-session bootstrap gate:

    1. manifest      : -Manifest exists, parses as JSON, and declares a required_reads array
    2. required_reads: every required_read path exists on disk
    3. git           : repo has HEAD; reports branch + dirty count (git status --porcelain)
    4. readiness     : 09_SOP/SESSION_READINESS.md exists; with -ProjectName also verifies
                       01_Projects/<name>/ADAPTER.md exists and 12_Indexes/project_index.json
                       resolves the project (resolution logic mirrors scripts/simulate-bootstrap.ps1)

  Output is human-readable text by default; with -Json a single JSON object is emitted:
    { manifest_version, checks:[{name,status,detail}], branch, dirty_count,
      gates_passed, gates_failed, gates_warn, verdict }

  Exit 0 when no FAIL; 1 when any FAIL. WARN never fails unless -Strict (then any WARN -> exit 1).

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-bootstrap.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-bootstrap.ps1 -ProjectName goffice2026

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-bootstrap.ps1 -ProjectName goffice2026 -Json -Strict
#>
[CmdletBinding()]
param(
    [string]$Manifest = '09_SOP/bootstrap-manifest.json',
    [string]$ProjectName,
    [switch]$Json,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 ignores this; PS 7.3+ only. Keeps native git errors non-terminating.
if ($PSVersionTable.PSEdition -eq 'Core') { $PSNativeCommandUseErrorActionPreference = $false }

$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '..'))

function Get-ManifestPath {
    param([Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return Join-Path $Root ($Path -replace '/', [IO.Path]::DirectorySeparatorChar)
}

function Add-Check {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Status,
        [string]$Detail = ''
    )
    $script:Checks.Add([ordered]@{ name = $Name; status = $Status; detail = $Detail }) | Out-Null
}

# Resolution logic mirrors scripts/simulate-bootstrap.ps1 Resolve-ProjectEntry.
function Resolve-ProjectEntry {
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
        if ($path) {
            $seg = ($path.TrimEnd('/') -split '/')[-1]
            if ($seg -and $seg.ToLowerInvariant() -eq $nameLower) {
                return @{ Entry = $entry; MatchedBy = 'path' }
            }
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

$Checks = New-Object System.Collections.Generic.List[object]
$ManifestVersion = 'unknown'
$Branch = 'n/a'
$DirtyCount = -1

# --- Check 1: manifest exists + valid JSON + required_reads array -------------------------
$manifestFull = Get-ManifestPath -Path $Manifest
$requiredReads = @()
if (-not (Test-Path -LiteralPath $manifestFull -PathType Leaf)) {
    Add-Check -Name 'manifest' -Status 'FAIL' -Detail "missing $Manifest"
}
else {
    try {
        $manifestDoc = Get-Content -LiteralPath $manifestFull -Raw | ConvertFrom-Json
        if ($null -ne $manifestDoc.version) { $ManifestVersion = [string]$manifestDoc.version }
        if ($manifestDoc.PSObject.Properties.Name -notcontains 'required_reads') {
            Add-Check -Name 'manifest' -Status 'FAIL' -Detail 'valid JSON but no required_reads array'
        }
        else {
            $requiredReads = @($manifestDoc.required_reads)
            if ($requiredReads.Count -eq 0) {
                Add-Check -Name 'manifest' -Status 'WARN' -Detail 'required_reads is an empty array'
            }
            else {
                Add-Check -Name 'manifest' -Status 'PASS' -Detail ("version $ManifestVersion; required_reads ({0})" -f $requiredReads.Count)
            }
        }
    }
    catch {
        Add-Check -Name 'manifest' -Status 'FAIL' -Detail ("invalid JSON: {0}" -f $_.Exception.Message)
    }
}

# --- Check 2: every required_read path exists on disk --------------------------------------
foreach ($rel in $requiredReads) {
    if ($null -eq $rel -or [string]::IsNullOrWhiteSpace([string]$rel)) {
        Add-Check -Name 'required_read:<null>' -Status 'FAIL' -Detail 'required_reads contains a null/empty entry'
        continue
    }
    $relStr = [string]$rel
    $full = Join-Path $Root ($relStr -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $full) {
        Add-Check -Name ("required_read:{0}" -f $relStr) -Status 'PASS' -Detail 'exists'
    }
    else {
        Add-Check -Name ("required_read:{0}" -f $relStr) -Status 'FAIL' -Detail 'missing on disk'
    }
}

# --- Check 3: git repo has HEAD; report branch + dirty count --------------------------------
$hasHead = $false
Push-Location $Root
try {
    & git rev-parse --verify HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $hasHead = $true }
}
catch {
    $hasHead = $false
}
if ($hasHead) {
    try {
        $br = & git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $br) { $br = 'HEAD' }
        $Branch = [string]($br | Select-Object -First 1)

        $porcelain = @(& git status --porcelain 2>$null)
        $DirtyCount = 0
        foreach ($line in $porcelain) {
            if ($null -ne $line -and ([string]$line).Trim().Length -gt 0) { $DirtyCount++ }
        }
        Add-Check -Name 'git_head' -Status 'PASS' -Detail ("branch={0} dirty={1}" -f $Branch, $DirtyCount)
    }
    catch {
        Add-Check -Name 'git_head' -Status 'FAIL' -Detail ("git inspect failed: {0}" -f $_.Exception.Message)
    }
}
else {
    Add-Check -Name 'git_head' -Status 'FAIL' -Detail 'no HEAD (unborn branch or not a git repo)'
}
Pop-Location

# --- Check 4: readiness artifact (+ project adapter + index resolution) ---------------------
$readinessRel = '09_SOP/SESSION_READINESS.md'
$readinessFull = Join-Path $Root ($readinessRel -replace '/', [IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $readinessFull) {
    Add-Check -Name 'readiness_artifact' -Status 'PASS' -Detail $readinessRel
}
else {
    Add-Check -Name 'readiness_artifact' -Status 'FAIL' -Detail "missing $readinessRel"
}

if ($ProjectName) {
    $adapterRel = "01_Projects/$ProjectName/ADAPTER.md"
    $adapterFull = Join-Path $Root ($adapterRel -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $adapterFull -PathType Leaf) {
        Add-Check -Name 'adapter' -Status 'PASS' -Detail $adapterRel
    }
    else {
        Add-Check -Name 'adapter' -Status 'FAIL' -Detail "missing $adapterRel"
    }

    $indexRel = '12_Indexes/project_index.json'
    $indexFull = Join-Path $Root ($indexRel -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $indexFull -PathType Leaf)) {
        Add-Check -Name 'index_resolution' -Status 'FAIL' -Detail "missing $indexRel"
    }
    else {
        try {
            $indexDoc = Get-Content -LiteralPath $indexFull -Raw | ConvertFrom-Json
            $entries = @()
            if ($indexDoc.PSObject.Properties.Name -contains 'entries') { $entries = @($indexDoc.entries) }
            $match = Resolve-ProjectEntry -Entries $entries -Name $ProjectName
            if ($null -ne $match) {
                Add-Check -Name 'index_resolution' -Status 'PASS' -Detail ("resolved '{0}' by {1} -> {2}" -f $ProjectName, $match.MatchedBy, $match.Entry.id)
            }
            else {
                Add-Check -Name 'index_resolution' -Status 'FAIL' -Detail ("'{0}' not found in {1}" -f $ProjectName, $indexRel)
            }
        }
        catch {
            Add-Check -Name 'index_resolution' -Status 'FAIL' -Detail ("unparseable {0}: {1}" -f $indexRel, $_.Exception.Message)
        }
    }
}

# --- Aggregate + verdict ---------------------------------------------------------------------
$Passed = @($Checks | Where-Object { $_.status -eq 'PASS' }).Count
$Failed = @($Checks | Where-Object { $_.status -eq 'FAIL' }).Count
$Warned = @($Checks | Where-Object { $_.status -eq 'WARN' }).Count

$Verdict = 'PASS'
if ($Failed -gt 0) { $Verdict = 'FAIL' }
elseif ($Warned -gt 0) { $Verdict = 'WARN' }
if ($Strict -and $Warned -gt 0 -and $Verdict -eq 'WARN') { $Verdict = 'FAIL' }

$result = [ordered]@{
    manifest_version = $ManifestVersion
    checks           = $Checks
    branch           = $Branch
    dirty_count      = $DirtyCount
    gates_passed     = $Passed
    gates_failed     = $Failed
    gates_warn       = $Warned
    verdict          = $Verdict
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 6)
}
else {
    Write-Output 'AI-OS Bootstrap Gate'
    Write-Output ("manifest: {0}  (version {1})" -f $Manifest, $ManifestVersion)
    Write-Output ("git: branch={0} dirty={1}" -f $Branch, $DirtyCount)
    Write-Output ''
    foreach ($c in $Checks) {
        Write-Output ("{0,-4} {1}  {2}" -f $c.status, $c.name, $c.detail)
    }
    Write-Output ''
    Write-Output ("GATES passed={0} failed={1} warn={2}" -f $Passed, $Failed, $Warned)
    Write-Output ("VERDICT: {0}" -f $Verdict)
}

if ($Verdict -eq 'FAIL') { exit 1 }
exit 0
