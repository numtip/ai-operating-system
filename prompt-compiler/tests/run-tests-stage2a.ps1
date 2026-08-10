<#
.SYNOPSIS
  Deterministic tests for AI-OS Stage 2A cost telemetry + budget guard.
  No LLM, no network, no real provider calls — local fixtures only.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests-stage2a.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '../..'))
$telemetry = Join-Path $Root 'prompt-compiler/runtime/Cost-Telemetry.ps1'
. $telemetry

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

# Fixtures
$mock = Read-CostJson -FullPath (Join-Path $Root 'prompt-compiler/fixtures/mock-provider-response.json')
$rates = Get-CostRateTable
$usage = $mock.usage

# --- 1. run id: deterministic from seed, unique without ---
$idA = New-CostRunId -Seed 'same-task-contract'
$idB = New-CostRunId -Seed 'same-task-contract'
$idC = New-CostRunId -Seed 'other-task-contract'
$idRand = New-CostRunId
Assert-True '1a.run_id_deterministic_from_seed' ($idA -eq $idB) "a=$idA b=$idB"
Assert-True '1b.run_id_differs_across_seeds' ($idA -ne $idC)
Assert-True '1c.run_id_format' ($idA -match '^run-[0-9a-f]{16}$') "id=$idA"
Assert-True '1d.run_id_auto_generated' ($idRand -match '^run-[0-9a-f]{32}$') "id=$idRand"

# --- 2. run record: identity + token fields ---
$rec = New-CostRunRecord -Provider 'deepseek' -Model 'deepseek-v4-flash' -Usage $usage -RateTable $rates `
    -RunId $idA -TimestampUtc '2026-08-10T00:00:00Z' -TaskFingerprint 'fp-mock-1' -ApiCalls 12 -Verdict 'PASS_WITH_NOTES'
Assert-True '2a.record_run_id' ($rec.run_id -eq $idA)
Assert-True '2b.record_timestamp' ($rec.timestamp_utc -eq '2026-08-10T00:00:00Z')
Assert-True '2c.record_provider_model' ($rec.provider -eq 'deepseek' -and $rec.model -eq 'deepseek-v4-flash')
Assert-True '2d.record_tokens' ($rec.usage.input_tokens -eq 31372 -and $rec.usage.output_tokens -eq 17411 -and $rec.usage.total_tokens -eq 324495) "total=$($rec.usage.total_tokens)"

# --- 3. cost estimate: assumptions + rate source + UNVERIFIED_RATE ---
$est = Invoke-CostEstimate -Usage $usage -RateTable $rates
Assert-True '3a.estimate_computed' ($null -ne $est.estimated_cost_usd -and $est.estimated_cost_usd -gt 0) "cost=$($est.estimated_cost_usd)"
Assert-True '3b.estimate_unverified_flag' ($est.unverified_rate -eq $true -and $est.rate_status -eq 'UNVERIFIED_RATE') "status=$($est.rate_status)"
Assert-True '3c.estimate_rate_source_stated' (-not [string]::IsNullOrWhiteSpace($est.rate_source))
Assert-True '3d.estimate_assumptions_stated' (@($est.assumptions).Count -ge 3) "assumptions=$(@($est.assumptions).Count)"
Assert-True '3e.estimate_not_billing_fact' ((@($est.assumptions | Where-Object { $_ -match 'NOT a billing fact|not a billing fact' }).Count) -ge 1)

# --- 4. preflight: missing cap blocks; valid cap ready ---
$pfBad = Invoke-CostBudgetPreflight -CapUsd 0 -CapTokens 0
Assert-True '4a.preflight_no_cap_blocked' (-not $pfBad.ok -and $pfBad.decision -eq 'BLOCKED') "decision=$($pfBad.decision)"
$pfGood = Invoke-CostBudgetPreflight -CapUsd 0.02 -CapTokens 0
Assert-True '4b.preflight_valid_cap_ready' ($pfGood.ok -and $pfGood.decision -eq 'READY') "decision=$($pfGood.decision)"
$pfToken = Invoke-CostBudgetPreflight -CapUsd 0 -CapTokens 100000
Assert-True '4c.preflight_token_cap_ready' ($pfToken.ok -and $pfToken.decision -eq 'READY')

# --- 5. budget guard: cap boundary (exactly at cap = ALLOW; over = BUDGET_EXCEEDED) ---
$gAt = Invoke-CostBudgetGuard -EstimatedCostUsd 0.02 -TotalTokens 324495 -CapUsd 0.02 -CapTokens 0
Assert-True '5a.guard_at_usd_cap_allowed' ($gAt.decision -eq 'ALLOW' -and $null -eq $gAt.stop_result) "decision=$($gAt.decision)"
$gOver = Invoke-CostBudgetGuard -EstimatedCostUsd 0.02000001 -TotalTokens 324495 -CapUsd 0.02 -CapTokens 0
Assert-True '5b.guard_over_usd_cap_exceeded' ($gOver.decision -eq 'BUDGET_EXCEEDED' -and $gOver.stop_result -eq 'BUDGET_EXCEEDED') "decision=$($gOver.decision)"
$gTokAt = Invoke-CostBudgetGuard -EstimatedCostUsd 0 -TotalTokens 324495 -CapUsd 0 -CapTokens 324495
Assert-True '5c.guard_at_token_cap_allowed' ($gTokAt.decision -eq 'ALLOW')
$gTokOver = Invoke-CostBudgetGuard -EstimatedCostUsd 0 -TotalTokens 324496 -CapUsd 0 -CapTokens 324495
Assert-True '5d.guard_over_token_cap_exceeded' ($gTokOver.decision -eq 'BUDGET_EXCEEDED') "decision=$($gTokOver.decision)"
$gBoth = Invoke-CostBudgetGuard -EstimatedCostUsd 0.03 -TotalTokens 100 -CapUsd 0.02 -CapTokens 100000
Assert-True '5e.guard_either_cap_triggers' ($gBoth.decision -eq 'BUDGET_EXCEEDED') "decision=$($gBoth.decision) reasons=$($gBoth.reasons -join '; ')"

# --- 6. record carries budget decision + stop result ---
$recOver = New-CostRunRecord -Provider 'deepseek' -Model 'deepseek-v4-flash' -Usage $usage -RateTable $rates `
    -RunId 'run-cap-over' -TimestampUtc '2026-08-10T00:00:00Z' -TaskFingerprint 'fp-mock-1' -BudgetCapUsd 0.001
Assert-True '6a.record_budget_exceeded' ($recOver.budget_decision -eq 'BUDGET_EXCEEDED' -and $recOver.stop_result -eq 'BUDGET_EXCEEDED') "decision=$($recOver.budget_decision)"
$recOk = New-CostRunRecord -Provider 'deepseek' -Model 'deepseek-v4-flash' -Usage $usage -RateTable $rates `
    -RunId 'run-ok' -TimestampUtc '2026-08-10T00:00:00Z' -TaskFingerprint 'fp-mock-1' -BudgetCapUsd 10
Assert-True '6b.record_budget_allowed' ($recOk.budget_decision -eq 'ALLOW')

# --- 7. redaction: no prompt/raw by default; masking works ---
Assert-True '7a.default_no_prompt_stored' (-not $rec.prompt_stored -and -not $rec.PSObject.Properties.Name.Contains('prompt'))
Assert-True '7b.default_no_raw_response' (-not $rec.raw_response_stored)
$masked = ConvertTo-CostRedactedText -Text 'Authorization: Bearer abcdefghijkl1234567890 and api_key = super-secret-value-xyz'
Assert-True '7c.redaction_masks_secrets' ($masked -match 'REDACTED' -and $masked -notmatch 'abcdefghijkl1234567890' -and $masked -notmatch 'super-secret-value-xyz') "masked=$masked"
$red = ConvertTo-CostRedactedRecord -Record $rec
Assert-True '7d.redacted_record_summary_only' ($red.redacted -and $red.run_id -eq $idA -and -not $red.PSObject.Properties.Name.Contains('prompt'))

# --- 8. fingerprint determinism ---
$fp1 = Get-CostRunFingerprint -Prompt "Audit goffice2026 read-only.`r`nSecond line" -ContextPaths @('07_Memory/CURRENT_STATE.md', '12_Indexes/project_index.json') -Model 'deepseek-v4-flash'
$fp2 = Get-CostRunFingerprint -Prompt "Audit goffice2026 read-only.`nSecond line" -ContextPaths @('12_Indexes/project_index.json', '07_Memory/CURRENT_STATE.md') -Model 'deepseek-v4-flash'
$fp3 = Get-CostRunFingerprint -Prompt "Audit goffice2026 read-only." -ContextPaths @('07_Memory/CURRENT_STATE.md') -Model 'deepseek-v4-flash'
Assert-True '8a.fingerprint_stable_across_line_endings_order' ($fp1 -eq $fp2) "a=$fp1 b=$fp2"
Assert-True '8b.fingerprint_changes_with_content' ($fp1 -ne $fp3)

# --- 9. billing variance (human-entered billed amount) ---
$vOk = Test-CostBillingVariance -LocalUsd 0.010 -BilledUsd 0.011 -TolerancePct 20
Assert-True '9a.variance_within_tolerance' ($vOk.within_tolerance -and $vOk.variance_pct -eq 10.0) "variance=$($vOk.variance_pct)"
$vBad = Test-CostBillingVariance -LocalUsd 0.010 -BilledUsd 0.02 -TolerancePct 20
Assert-True '9b.variance_outside_tolerance' (-not $vBad.within_tolerance) "variance=$($vBad.variance_pct)"
$vZero = Test-CostBillingVariance -LocalUsd 0 -BilledUsd 0.01 -TolerancePct 20
Assert-True '9c.variance_unknown_when_no_local' ($null -eq $vZero.variance_pct -and -not $vZero.within_tolerance)

Write-Host ''
Write-Host ("STAGE-2A SUMMARY passed={0} failed={1}" -f $passed, $failed)
if ($failed -gt 0) { exit 1 } else { exit 0 }
