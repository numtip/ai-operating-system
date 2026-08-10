<#
.SYNOPSIS
  Stage 2A -- bounded live-run orchestrator (max 3 runs, cap-enforced).
.DESCRIPTION
  Runs up to -Runs real DeepSeek chat calls (default 3) for a synthetic,
  AI-OS-internal L0/L1 read-only task. Each call happens in a CHILD process
  (Invoke-DeepSeekCall.ps1) which loads the key from the external secret file;
  this parent never reads the key.

  Security contract:
    - Preflight must pass before any request (Invoke-Stage2aPreflight).
    - Run caps (model, cap_usd, cap_total_tokens, max_output_tokens) come from
      stage2a-run-config.json and are set before firing any request.
    - Stops immediately on BUDGET_EXCEEDED or on any failed call.
    - Evidence stores tokens/cost/fingerprint only -- never the key or prompt.
    - Billing reconciliation stays null (human-entered later).
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File Invoke-Stage2aLiveRun.ps1 -Runs 3
#>
[CmdletBinding()]
param(
    [int]$Runs = 3,
    [string]$SecretPath = '',
    [string]$RepoRoot = ''
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

. (Join-Path $PSScriptRoot 'Secret-Loader.ps1')
. (Join-Path $PSScriptRoot 'Cost-Telemetry.ps1')

if (-not $RepoRoot) { $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')) }
if ($Runs -gt 3) { $Runs = 3 }   # hard bound: max 3 comparable runs

# --- Preflight (value-safe) before any request ---
$pf = Invoke-Stage2aPreflight -SecretPath $SecretPath -RepoRoot $RepoRoot
if (-not $pf.ok) {
    $failedNames = @($pf.checks | Where-Object { $_.status -eq 'FAIL' } | ForEach-Object { $_.name }) -join ', '
    throw ("preflight blocked: {0} - {1}" -f $pf.verdict, $failedNames)
}
$cfg = Get-Stage2aRunConfig -RepoRoot $RepoRoot
$task = 'Reply with the single token OK.'   # synthetic, AI-OS-internal; no target-project data
$fp = Get-CostRunFingerprint -Prompt $task -ContextPaths @() -Model $cfg.model
$child = Join-Path $PSScriptRoot 'Invoke-DeepSeekCall.ps1'

# Preflight cost projection: block BEFORE any network request if the cap is below
# the conservative minimum cost of the task.
$preGuard = Invoke-CostPreflightGuard -Prompt $task -CapUsd ([double]$cfg.cap_usd) -CapTokens ([long]$cfg.cap_total_tokens)
if ($preGuard.decision -eq 'BUDGET_EXCEEDED') {
    throw ("preflight cost projection BLOCKED before any request: {0} (min_input_tokens={1})" -f `
        $preGuard.stop_result, $preGuard.min_input_tokens)
}

Write-Host ("Stage 2A live run starting: runs={0} model={1} cap_usd={2} cap_tokens={3} max_out={4}" -f `
    $Runs, $cfg.model, $cfg.cap_usd, $cfg.cap_total_tokens, $cfg.max_output_tokens)

$records = New-Object System.Collections.Generic.List[object]
$stoppedEarly = $false
$stopReason = ''

for ($i = 1; $i -le $Runs; $i++) {
    $raw = & powershell -NoProfile -ExecutionPolicy Bypass -File $child `
        -SecretPath $pf.secret_path -Prompt $task -Model $cfg.model -MaxTokens ([int]$cfg.max_output_tokens) 2>$null
    if ($LASTEXITCODE -ne 0) {
        $stoppedEarly = $true
        $stopReason = "child process failed (exit=$LASTEXITCODE) on run $i"
        break
    }
    $res = $null
    try { $res = ($raw -join "`n") | ConvertFrom-Json } catch { $res = $null }
    if ($null -eq $res -or -not $res.ok) {
        $code = if ($res -and $null -ne $res.status_code) { $res.status_code } else { 'unknown' }
        $stoppedEarly = $true
        $stopReason = "API call failed on run $i (http=$code)"
        break
    }

    $record = New-CostRunRecord -Provider 'deepseek' -Model $cfg.model -Usage $res.usage `
        -RunId (New-CostRunId -Seed ("live-run-{0}" -f $i)) `
        -TimestampUtc ([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')) `
        -TaskFingerprint $fp -ApiCalls 1 -Verdict 'ALLOW' `
        -BudgetCapUsd ([double]$cfg.cap_usd) -BudgetCapTokens ([long]$cfg.cap_total_tokens)
    $record | Add-Member -NotePropertyName latency_seconds -NotePropertyValue ([double]$res.latency_seconds)
    $records.Add($record) | Out-Null

    Write-Host ("run {0}: {1} in/ {2} out/ {3} total tok | est {4} | {5}" -f $i, `
        $record.usage.input_tokens, $record.usage.output_tokens, $record.usage.total_tokens, `
        $record.estimated_cost_usd, $record.budget_decision)

    if ($record.budget_decision -eq 'BUDGET_EXCEEDED') {
        $stoppedEarly = $true
        $stopReason = "BUDGET_EXCEEDED on run $i (stop_result=$($record.stop_result))"
        break
    }
}

$evidence = [ordered]@{
    schema_version = '1.0'
    protocol       = [ordered]@{
        id            = 'stage-2a-comparable-run-v1'
        task          = $task
        mode          = 'LIVE'
        tolerance_pct = 20
    }
    provider          = 'deepseek'
    model             = $cfg.model
    task_fingerprint  = $fp
    cap               = [ordered]@{
        cap_usd           = [double]$cfg.cap_usd
        cap_total_tokens  = [long]$cfg.cap_total_tokens
        max_output_tokens = [int]$cfg.max_output_tokens
    }
    rate_status       = 'UNVERIFIED_RATE'
    rate_source       = 'official pricing docs snapshot -- NOT confirmed by owner or provider billing; verify before any spend decision'
    runs              = $records.ToArray()
    stopped_early     = $stoppedEarly
    stop_reason       = $stopReason
    billing_reconciliation = [ordered]@{
        billed_usd       = $null
        variance_pct     = $null
        within_tolerance = $null
        filled_by_human_at = $null
    }
    redaction         = 'no key, no prompt content, no raw payload stored'
}

$evPath = Join-Path $RepoRoot '06_Research/pilots/v1.6-hermes/STAGE-2A-LIVE-EVIDENCE.json'
$json = $evidence | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($evPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("evidence written: {0} (runs recorded: {1})" -f $evPath, $records.Count)
if ($stoppedEarly) { throw "live run stopped early: $stopReason" }
Write-Host 'LIVE RUN COMPLETE: 3 runs recorded under caps.'
