<#
.SYNOPSIS
  AI-OS v1.1 composite validation: structure + indexes + session threshold check.
.DESCRIPTION
  Runs validate-structure.ps1 and validate-indexes.ps1.
  If 07_Memory/compression/THRESHOLD.json exists, compares session file count
  under 07_Memory/sessions to session_count_threshold (default 25).
  If THRESHOLD.json is missing, skips with WARN (does not fail).
  Exit 0 if structure+indexes pass; 1 if either fails.
  Threshold overrun prints WARN but does not fail the composite exit code.
  Run from repo root:
    pwsh -File scripts/validate-v1.1.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-v1.1.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$failed = 0

function Invoke-ChildScript {
    param(
        [Parameter(Mandatory)][string]$RelativeScript,
        [Parameter(Mandatory)][string]$Label
    )
    $scriptPath = Join-Path $Root $RelativeScript
    Write-Host "=== $Label ==="
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        Write-Host "FAIL  missing $RelativeScript"
        $script:failed++
        Write-Host ""
        return
    }
    & $scriptPath
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
    if ($code -ne 0) {
        Write-Host "FAIL  $RelativeScript exited $code"
        $script:failed++
    }
    else {
        Write-Host "PASS  $RelativeScript"
    }
    Write-Host ""
}

Write-Host "AI-OS v1.1 validation under: $Root"
Write-Host ""

Invoke-ChildScript -RelativeScript 'scripts/validate-structure.ps1' -Label 'Structure'
Invoke-ChildScript -RelativeScript 'scripts/validate-indexes.ps1' -Label 'Indexes'

Write-Host "=== Session threshold ==="
$thresholdPath = Join-Path $Root '07_Memory/compression/THRESHOLD.json'
$defaultThreshold = 25

if (-not (Test-Path -LiteralPath $thresholdPath -PathType Leaf)) {
    Write-Host "WARN  07_Memory/compression/THRESHOLD.json missing - skipping session threshold check"
}
else {
    try {
        $thresholdDoc = [System.IO.File]::ReadAllText($thresholdPath) | ConvertFrom-Json
        $threshold = $defaultThreshold
        if ($null -ne $thresholdDoc.session_count_threshold) {
            $threshold = [int]$thresholdDoc.session_count_threshold
        }
        $sessionsRoot = Join-Path $Root '07_Memory/sessions'
        $sessionCount = 0
        if (Test-Path -LiteralPath $sessionsRoot -PathType Container) {
            $sessionCount = @(Get-ChildItem -LiteralPath $sessionsRoot -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -notmatch '[\\/]archive[\\/]' }).Count
        }
        Write-Host "INFO  session_count=$sessionCount threshold=$threshold"
        if ($sessionCount -ge $threshold) {
            Write-Host "WARN  session count ($sessionCount) reached/exceeded threshold ($threshold) - consider compression"
        }
        else {
            Write-Host "PASS  session count below threshold"
        }
    }
    catch {
        Write-Host "WARN  could not evaluate THRESHOLD.json - $($_.Exception.Message)"
    }
}

Write-Host ""
if ($failed -eq 0) {
    Write-Host "RESULT: PASS (v1.1)"
    exit 0
}
else {
    Write-Host ('RESULT: FAIL (v1.1) ({0} step(s) failed)' -f $failed)
    exit 1
}