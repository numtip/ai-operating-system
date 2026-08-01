<#
.SYNOPSIS
  Tests for scripts/check-bootstrap.ps1 (AI-OS v1.5 Bootstrap Gate).
.DESCRIPTION
  Runs check-bootstrap.ps1 as a child process (so its exit codes are real)
  and asserts: exit codes, verdicts, JSON output parseability, per-gate statuses,
  branch/dirty reporting, and WARN vs -Strict behavior.
  Stdlib PowerShell only. Windows PowerShell 5.x or PowerShell 7.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-check-bootstrap.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '../..'))
$checker = Join-Path $Root 'scripts/check-bootstrap.ps1'
if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
    throw "checker not found: $checker"
}
$engine = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }

$passed = 0
$failed = 0
$results = New-Object System.Collections.Generic.List[object]

function Assert-True {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        $script:passed++
        $script:results.Add([ordered]@{ name = $Name; status = 'PASS'; detail = $Detail }) | Out-Null
        Write-Host "PASS  $Name"
    }
    else {
        $script:failed++
        $script:results.Add([ordered]@{ name = $Name; status = 'FAIL'; detail = $Detail }) | Out-Null
        Write-Host "FAIL  $Name  $Detail"
    }
}

function Invoke-Checker {
    param(
        [string[]]$ArgList,
        [switch]$JsonOut
    )
    $output = & $engine -NoProfile -ExecutionPolicy Bypass -File $checker @ArgList 2>&1
    $code = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    $obj = $null
    if ($JsonOut) {
        try { $obj = $text | ConvertFrom-Json } catch { $obj = $null }
    }
    return [pscustomobject]@{ ExitCode = $code; Text = $text; Json = $obj }
}

function Get-CheckStatus {
    param($Json, [string]$Name, [string]$Status)
    return @($Json.checks | Where-Object { $_.name -eq $Name -and $_.status -eq $Status }).Count
}

Write-Host "engine: $engine"
Write-Host "checker: $checker"
Write-Host ''

# Actual branch for comparison
$actualBranch = 'n/a'
Push-Location $Root
try {
    $br = & git rev-parse --abbrev-ref HEAD 2>$null
    if ($br) { $actualBranch = [string]($br | Select-Object -First 1) }
}
catch { }
Pop-Location

# --- 1. default human run ---------------------------------------------------------------
$r1 = Invoke-Checker -ArgList @()
Assert-True '1.default_exit_0' ($r1.ExitCode -eq 0) ("exit=$($r1.ExitCode)")
Assert-True '1.default_verdict_pass' ($r1.Text -match 'VERDICT: PASS') $r1.Text
Assert-True '1.default_reports_git' ($r1.Text -match 'git: branch=') $r1.Text
Assert-True '1.default_has_pass_lines' ($r1.Text -match '(?m)^PASS') $r1.Text

# --- 2. JSON mode ------------------------------------------------------------------------
$r2 = Invoke-Checker -ArgList @('-Json') -JsonOut
Assert-True '2.json_exit_0' ($r2.ExitCode -eq 0) ("exit=$($r2.ExitCode)")
Assert-True '2.json_parses' ($null -ne $r2.Json) $r2.Text
Assert-True '2.json_verdict_pass' ($r2.Json.verdict -eq 'PASS') $r2.Text
Assert-True '2.json_checks_array' (@($r2.Json.checks).Count -gt 0) 'checks empty'
Assert-True '2.json_manifest_version' (-not [string]::IsNullOrWhiteSpace([string]$r2.Json.manifest_version)) $r2.Text
Assert-True '2.json_branch_reported' (-not [string]::IsNullOrWhiteSpace([string]$r2.Json.branch)) $r2.Text
Assert-True '2.json_branch_matches_git' ([string]$r2.Json.branch -eq $actualBranch) ("checker=$($r2.Json.branch) git=$actualBranch")
Assert-True '2.json_dirty_count_nonnegative' ($r2.Json.dirty_count -ge 0) "dirty=$($r2.Json.dirty_count)"
Assert-True '2.json_gates_failed_zero' ($r2.Json.gates_failed -eq 0) "failed=$($r2.Json.gates_failed)"
$missingKeys = @('manifest_version', 'checks', 'branch', 'dirty_count', 'gates_passed', 'gates_failed', 'verdict') |
    Where-Object { $r2.Json.PSObject.Properties.Name -notcontains $_ }
Assert-True '2.json_keys_present' (@($missingKeys).Count -eq 0) ("missing: $($missingKeys -join ', ')")

# --- 3. missing manifest ------------------------------------------------------------------
$r3 = Invoke-Checker -ArgList @('-Manifest', '09_SOP/does-not-exist.json', '-Json') -JsonOut
Assert-True '3.missing_manifest_exit_1' ($r3.ExitCode -eq 1) ("exit=$($r3.ExitCode)")
Assert-True '3.missing_manifest_parses' ($null -ne $r3.Json) $r3.Text
Assert-True '3.missing_manifest_verdict_fail' ($r3.Json.verdict -eq 'FAIL') $r3.Text
Assert-True '3.missing_manifest_gates_failed_ge_1' ($r3.Json.gates_failed -ge 1) "failed=$($r3.Json.gates_failed)"
Assert-True '3.missing_manifest_check_fail' ((Get-CheckStatus -Json $r3.Json -Name 'manifest' -Status 'FAIL') -eq 1) $r3.Text

# --- 4. unknown project --------------------------------------------------------------------
$r4 = Invoke-Checker -ArgList @('-ProjectName', 'no-such-project-xyz', '-Json') -JsonOut
Assert-True '4.unknown_project_exit_1' ($r4.ExitCode -eq 1) ("exit=$($r4.ExitCode)")
Assert-True '4.unknown_project_verdict_fail' ($r4.Json.verdict -eq 'FAIL') $r4.Text
Assert-True '4.unknown_project_adapter_fail' ((Get-CheckStatus -Json $r4.Json -Name 'adapter' -Status 'FAIL') -eq 1) $r4.Text
Assert-True '4.unknown_project_index_fail' ((Get-CheckStatus -Json $r4.Json -Name 'index_resolution' -Status 'FAIL') -eq 1) $r4.Text

# --- 5. valid project -----------------------------------------------------------------------
$r5 = Invoke-Checker -ArgList @('-ProjectName', 'goffice2026', '-Json') -JsonOut
Assert-True '5.valid_project_exit_0' ($r5.ExitCode -eq 0) ("exit=$($r5.ExitCode)")
Assert-True '5.valid_project_verdict_pass' ($r5.Json.verdict -eq 'PASS') $r5.Text
Assert-True '5.valid_project_adapter_pass' ((Get-CheckStatus -Json $r5.Json -Name 'adapter' -Status 'PASS') -eq 1) $r5.Text
Assert-True '5.valid_project_index_pass' ((Get-CheckStatus -Json $r5.Json -Name 'index_resolution' -Status 'PASS') -eq 1) $r5.Text

# --- 6. WARN semantics + -Strict -------------------------------------------------------------
$tmpManifest = Join-Path $env:TEMP ("check-bootstrap-warn-{0}.json" -f [guid]::NewGuid().ToString('N'))
try {
    [System.IO.File]::WriteAllText($tmpManifest, '{"version":"test","required_reads":[]}')
    $r6 = Invoke-Checker -ArgList @('-Manifest', $tmpManifest, '-Json') -JsonOut
    Assert-True '6.empty_reads_exit_0' ($r6.ExitCode -eq 0) ("exit=$($r6.ExitCode)")
    Assert-True '6.empty_reads_verdict_warn' ($r6.Json.verdict -eq 'WARN') $r6.Text
    Assert-True '6.empty_reads_manifest_warn' ((Get-CheckStatus -Json $r6.Json -Name 'manifest' -Status 'WARN') -eq 1) $r6.Text
    Assert-True '6.empty_reads_gates_failed_zero' ($r6.Json.gates_failed -eq 0) "failed=$($r6.Json.gates_failed)"

    $r6s = Invoke-Checker -ArgList @('-Manifest', $tmpManifest, '-Json', '-Strict') -JsonOut
    Assert-True '6.strict_warn_exit_1' ($r6s.ExitCode -eq 1) ("exit=$($r6s.ExitCode)")
    Assert-True '6.strict_warn_verdict_fail' ($r6s.Json.verdict -eq 'FAIL') $r6s.Text
}
finally {
    if (Test-Path -LiteralPath $tmpManifest) { Remove-Item -LiteralPath $tmpManifest -Force }
}

Write-Host ''
Write-Host ("SUMMARY passed={0} failed={1}" -f $passed, $failed)
if ($failed -gt 0) { exit 1 } else { exit 0 }
