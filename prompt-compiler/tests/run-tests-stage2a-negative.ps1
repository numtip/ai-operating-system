<#
.SYNOPSIS
  Stage 2A — live-safe negative tests: preflight BUDGET_EXCEEDED + zero network proof.
.DESCRIPTION
  Proves that when cap_usd is set below the conservative minimum cost, the
  preflight cost projection returns BUDGET_EXCEEDED BEFORE any network request,
  using a mockable transport with an invocation counter (NOT inference from
  absence of logs). A positive control proves the counter actually detects
  invocations when a call IS made.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests-stage2a-negative.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '../..'))
$telemetry = Join-Path $Root 'prompt-compiler/runtime/Cost-Telemetry.ps1'
. $telemetry

$passed = 0
$failed = 0

function Assert-True {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        $script:passed++
        Write-Host "PASS  $Name"
    }
    else {
        $script:failed++
        Write-Host "FAIL  $Name  $Detail"
    }
}

# --- 1. counter starts at 0 and resets (mock invoker set to avoid any real network) ---
Set-CostHttpInvoker -Invoker {
    param($Uri, $Headers, $Body, $TimeoutSec)
    return 'mocked'
}
Reset-CostHttpInvocationCount
Assert-True '1a.counter_starts_zero' ((Get-CostHttpInvocationCount) -eq 0)
$null = Invoke-CostHttpRequest -Uri 'https://mock.invalid/x' -Headers @{ a = 'b' } -Body '{}'
Assert-True '1b.counter_increments_on_invocation' ((Get-CostHttpInvocationCount) -eq 1) "count=$((Get-CostHttpInvocationCount))"
Reset-CostHttpInvocationCount
Assert-True '1c.counter_resets' ((Get-CostHttpInvocationCount) -eq 0)

# --- 2. positive control: mock invoker IS reachable and throws (proves detection works) ---
Set-CostHttpInvoker -Invoker {
    param($Uri, $Headers, $Body, $TimeoutSec)
    throw 'TRANSPORT_CALLED'
}
$caught = $false
try {
    Invoke-CostHttpRequest -Uri 'https://mock.invalid/x' -Headers @{ a = 'b' } -Body '{}'
}
catch { $caught = $true }
Assert-True '2a.mock_invoker_reachable' $caught
Assert-True '2b.counter_sees_control_call' ((Get-CostHttpInvocationCount) -eq 1) "count=$((Get-CostHttpInvocationCount))"
Reset-CostHttpInvocationCount
Set-CostHttpInvoker -Invoker $null

# --- 3. NEGATIVE TEST: cap below minimum cost -> preflight BUDGET_EXCEEDED, ZERO network ---
# Set mock invoker that would throw if any request were attempted; counter must stay 0.
Set-CostHttpInvoker -Invoker {
    param($Uri, $Headers, $Body, $TimeoutSec)
    throw 'NETWORK_REQUEST_ATTEMPTED_AFTER_PREFLIGHT_BLOCK'
}
Reset-CostHttpInvocationCount

$task = 'Reply with the single token OK.'
$capTinyUsd = 0.0000000001     # clearly below the minimum cost of the task
$capTinyTokens = 1L            # also below minimum tokens

$g = Invoke-CostPreflightGuard -Prompt $task -CapUsd $capTinyUsd -CapTokens $capTinyTokens
Assert-True '3a.preflight_returns_budget_exceeded' ($g.decision -eq 'BUDGET_EXCEEDED' -and $g.stop_result -eq 'BUDGET_EXCEEDED') "decision=$($g.decision)"
Assert-True '3b.zero_network_requests' ((Get-CostHttpInvocationCount) -eq 0) "count=$((Get-CostHttpInvocationCount))"

# --- 4. sanity: normal cap passes preflight projection (still zero network until request) ---
$g2 = Invoke-CostPreflightGuard -Prompt $task -CapUsd 0.02 -CapTokens 500000
Assert-True '4a.normal_cap_preflight_allows' ($g2.decision -eq 'ALLOW') "decision=$($g2.decision)"
Assert-True '4b.zero_network_after_allow_check' ((Get-CostHttpInvocationCount) -eq 0) "count=$((Get-CostHttpInvocationCount))"

# --- 5. token-cap negative too ---
$g3 = Invoke-CostPreflightGuard -Prompt $task -CapUsd 0 -CapTokens 2
Assert-True '5a.token_cap_below_min_exceeded' ($g3.decision -eq 'BUDGET_EXCEEDED') "decision=$($g3.decision)"
Assert-True '5b.zero_network_for_token_cap' ((Get-CostHttpInvocationCount) -eq 0) "count=$((Get-CostHttpInvocationCount))"

Set-CostHttpInvoker -Invoker $null
Reset-CostHttpInvocationCount

Write-Host ''
Write-Host ("STAGE-2A-NEGATIVE SUMMARY passed={0} failed={1}" -f $passed, $failed)
if ($failed -gt 0) { exit 1 } else { exit 0 }
