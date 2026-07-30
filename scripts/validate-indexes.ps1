<#
.SYNOPSIS
  Validates 12_Indexes JSON files: parse + every referenced path exists on disk.
.DESCRIPTION
  Stdlib PowerShell only. Exit 0 on pass, 1 on fail.
  Run from repo root:
    pwsh -File scripts/validate-indexes.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-indexes.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$IndexDir = Join-Path $Root '12_Indexes'
$failed = 0

$indexFiles = @(
    'knowledge_index.json',
    'project_index.json',
    'adr_index.json',
    'skill_index.json'
)

function Test-IndexFile {
    param([Parameter(Mandatory)][string]$FileName)

    $rel = "12_Indexes/$FileName"
    $full = Join-Path $IndexDir $FileName
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Write-Host "FAIL  [missing] $rel"
        $script:failed++
        return
    }

    try {
        $raw = [System.IO.File]::ReadAllText($full)
        $doc = $raw | ConvertFrom-Json
        Write-Host "PASS  [json] $rel"
    }
    catch {
        Write-Host "FAIL  [json] $rel - $($_.Exception.Message)"
        $script:failed++
        return
    }

    $hasSchema = $doc.PSObject.Properties.Name -contains 'schema_version'
    if (-not $hasSchema -or [string]::IsNullOrWhiteSpace([string]$doc.schema_version)) {
        Write-Host "FAIL  [schema] $rel - missing schema_version"
        $script:failed++
    }
    else {
        Write-Host "PASS  [schema] $rel schema_version=$($doc.schema_version)"
    }

    if (-not ($doc.PSObject.Properties.Name -contains 'entries')) {
        Write-Host "FAIL  [schema] $rel - missing entries array"
        $script:failed++
        return
    }

    $entries = @($doc.entries)
    if ($entries.Count -eq 0 -or ($entries.Count -eq 1 -and $null -eq $entries[0])) {
        Write-Host "PASS  [entries] $rel - empty entries (allowed)"
        return
    }

    $i = 0
    foreach ($entry in $entries) {
        $i++
        if ($null -eq $entry) { continue }
        foreach ($field in @('id', 'title', 'path')) {
            if (-not $entry.$field) {
                Write-Host "FAIL  [entry] $rel #$i - missing $field"
                $script:failed++
            }
        }
        $pathRel = [string]$entry.path
        if ([string]::IsNullOrWhiteSpace($pathRel)) { continue }

        $normalized = $pathRel.TrimEnd('/')
        $candidate = Join-Path $Root ($normalized -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (Test-Path -LiteralPath $candidate) {
            Write-Host "PASS  [path]  $pathRel"
        }
        else {
            Write-Host "FAIL  [path]  $pathRel (from $rel id=$($entry.id))"
            $script:failed++
        }
    }
}

Write-Host "Validating indexes under: $Root"
Write-Host ""

if (-not (Test-Path -LiteralPath $IndexDir -PathType Container)) {
    Write-Host "FAIL  [Directory] 12_Indexes"
    $failed++
}
else {
    Write-Host "PASS  [Directory] 12_Indexes"
}

foreach ($f in $indexFiles) {
    Test-IndexFile -FileName $f
}

Write-Host ""
if ($failed -eq 0) {
    Write-Host "RESULT: PASS"
    exit 0
}
else {
    Write-Host ('RESULT: FAIL ({0} check(s) failed)' -f $failed)
    exit 1
}