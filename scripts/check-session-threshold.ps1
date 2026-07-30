<#
.SYNOPSIS
  Count session markdown files under 07_Memory/sessions and compare to THRESHOLD.json.

.PARAMETER FailOnThreshold
  Exit 1 when count >= threshold (default: WARN and exit 0).
#>
[CmdletBinding()]
param(
  [switch]$FailOnThreshold
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sessionsDir = Join-Path $repoRoot '07_Memory\sessions'
$thresholdPath = Join-Path $repoRoot '07_Memory\compression\THRESHOLD.json'

if (-not (Test-Path -LiteralPath $thresholdPath)) {
  Write-Host "FAIL: missing threshold file: $thresholdPath"
  exit 1
}

$thresholdDoc = Get-Content -LiteralPath $thresholdPath -Raw | ConvertFrom-Json
$threshold = [int]$thresholdDoc.session_count_threshold

$sessionCount = 0
if (Test-Path -LiteralPath $sessionsDir) {
  $sessionCount = @(
    Get-ChildItem -LiteralPath $sessionsDir -Recurse -File -Filter '*.md' |
      Where-Object { $_.FullName -notmatch '[\\/]archive[\\/]' }
  ).Count
}

Write-Host "sessions_dir: $sessionsDir"
Write-Host "session_count: $sessionCount"
Write-Host "threshold: $threshold"

if ($sessionCount -lt $threshold) {
  Write-Host "RESULT: PASS (under threshold)"
  exit 0
}

$msg = "RESULT: WARN (session_count $sessionCount >= threshold $threshold) - consider compression"
if ($FailOnThreshold) {
  Write-Host ($msg -replace 'WARN', 'FAIL')
  exit 1
}

Write-Host $msg
exit 0
