<#
.SYNOPSIS
  AI-OS Stage 2A Cost Telemetry + Budget Guard (v0.1) — no LLM, no network, no secrets.
.DESCRIPTION
  Deterministic helpers for cost observability on governed L0/L1 read-only runs:

    - New-CostRunId            : run ID (deterministic from seed, else GUID)
    - Get-CostRateTable        : load rate table from JSON (UNVERIFIED_RATE unless verified)
    - Invoke-CostEstimate      : estimated cost from usage + rate table (never a billing fact)
    - New-CostRunRecord        : run record (run id, timestamp, provider/model, tokens, cost)
    - ConvertTo-CostRedactedText   : mask secret patterns
    - ConvertTo-CostRedactedRecord : strip prompt/raw content; keep only safe summary fields
    - Get-CostRunFingerprint   : deterministic prompt/context fingerprint
    - Invoke-CostBudgetPreflight  : validate cap configuration before a run
    - Invoke-CostBudgetGuard      : in-run cap check -> ALLOW | BUDGET_EXCEEDED
    - Test-CostBillingVariance    : local telemetry vs human-entered billing variance

  Defaults are redaction-safe: full prompt text and raw provider payloads are NEVER
  stored unless -IncludeRawResponse is passed, and even then the payload is masked.

  Dot-source:  . prompt-compiler/runtime/Cost-Telemetry.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CostTelemetryVersion = '0.1.0'
$script:CostSchemaVersion = '1.0'
$script:BudgetAllowed = 'ALLOW'
$script:BudgetExceeded = 'BUDGET_EXCEEDED'
$script:BudgetBlocked = 'BLOCKED'
$script:UnverifiedRate = 'UNVERIFIED_RATE'

# ---------------------------------------------------------------------------
# Small internal helpers (prefixed to avoid clashing with Compile-Prompt.ps1)
# ---------------------------------------------------------------------------

function Get-CostSha256 {
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

function Read-CostJson {
    param([Parameter(Mandatory)][string]$FullPath)
    return ([System.IO.File]::ReadAllText($FullPath) | ConvertFrom-Json)
}

function Get-CostRepoRoot {
    $here = $PSScriptRoot
    if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
    return [string](Resolve-Path (Join-Path $here '..\..'))
}

# ---------------------------------------------------------------------------
# Run identity
# ---------------------------------------------------------------------------

function New-CostRunId {
    param([AllowEmptyString()][string]$Seed = '')
    if ($Seed) {
        # deterministic: same seed -> same run id (test/comparability use)
        return 'run-' + (Get-CostSha256 -Text $Seed).Substring(0, 16)
    }
    return 'run-' + ([guid]::NewGuid().ToString('N'))
}

# ---------------------------------------------------------------------------
# Rate table
# ---------------------------------------------------------------------------

function Get-CostRateTable {
    param([string]$Path = '')
    if (-not $Path) {
        $Path = Join-Path (Join-Path (Get-CostRepoRoot) 'prompt-compiler/runtime') 'rate-table.json'
    }
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "rate table not found: $full"
    }
    return Read-CostJson -FullPath $full
}

# ---------------------------------------------------------------------------
# Cost estimation (never a billing fact)
# ---------------------------------------------------------------------------

function Invoke-CostEstimate {
    param(
        [Parameter(Mandatory)]$Usage,
        [Parameter(Mandatory)]$RateTable
    )
    # Token fields may be missing on some provider responses; default to 0.
    function Get-UsageField {
        param($Usage, [string]$Field)
        if ($null -eq $Usage) { return 0 }
        $props = $Usage.PSObject.Properties.Name
        if ($props -contains $Field) { return [long]$Usage.$Field }
        return 0
    }
    $inTok = Get-UsageField -Usage $Usage -Field 'input_tokens'
    $outTok = Get-UsageField -Usage $Usage -Field 'output_tokens'
    $cacheRead = Get-UsageField -Usage $Usage -Field 'cache_read_tokens'
    $cacheWrite = Get-UsageField -Usage $Usage -Field 'cache_write_tokens'
    $reasoning = Get-UsageField -Usage $Usage -Field 'reasoning_tokens'
    $total = Get-UsageField -Usage $Usage -Field 'total_tokens'
    if ($total -le 0) { $total = $inTok + $outTok }

    $verified = $false
    $rateStatus = $script:UnverifiedRate
    $rateSource = ''
    if ($RateTable -and $RateTable.PSObject.Properties.Name -contains 'verified') {
        $verified = [bool]$RateTable.verified
    }
    if ($RateTable -and $RateTable.PSObject.Properties.Name -contains 'rate_status') {
        $rateStatus = [string]$RateTable.rate_status
    }
    if ($RateTable -and $RateTable.PSObject.Properties.Name -contains 'rate_source') {
        $rateSource = [string]$RateTable.rate_source
    }

    $rates = $null
    if ($RateTable -and $RateTable.PSObject.Properties.Name -contains 'rates' -and $null -ne $RateTable.rates) {
        $rates = $RateTable.rates
    }
    $estimatedUsd = $null
    $assumptions = @(
        'tokens are provider-reported usage fields (input/output/cache/reasoning)',
        'cache_read_tokens billed at cache-read rate when provided; otherwise treated as input',
        'estimate is a planning figure only and is NOT a billing fact',
        "rate status = $rateStatus; verify rates against provider billing before any spend decision"
    )
    if ($rates) {
        $rIn = [double]$rates.input_per_mtok
        $rOut = [double]$rates.output_per_mtok
        $rCacheRead = [double]$rates.cache_read_per_mtok
        $rCacheWrite = [double]$rates.cache_write_per_mtok
        # cache_read is billed separately only when the provider reports it
        $cacheReadBilled = 0
        if ($cacheRead -gt 0) { $cacheReadBilled = $cacheRead }
        $est = ($inTok / 1e6 * $rIn) + ($outTok / 1e6 * $rOut) + ($cacheReadBilled / 1e6 * $rCacheRead) + ($cacheWrite / 1e6 * $rCacheWrite)
        $estimatedUsd = [Math]::Round($est, 8)
    }

    return [ordered]@{
        estimated_cost_usd  = $estimatedUsd
        unverified_rate     = (-not $verified)
        rate_status         = $rateStatus
        rate_source         = $rateSource
        assumptions         = $assumptions
        usage               = [ordered]@{
            input_tokens     = $inTok
            output_tokens    = $outTok
            cache_read_tokens = $cacheRead
            cache_write_tokens = $cacheWrite
            reasoning_tokens = $reasoning
            total_tokens     = $total
        }
    }
}

# ---------------------------------------------------------------------------
# Redaction
# ---------------------------------------------------------------------------

function ConvertTo-CostRedactedText {
    param([AllowEmptyString()][string]$Text = '')
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $masked = $Text
    $patterns = @(
        '(?i)\bauthorization\s*:\s*bearer\s+[^\s,;]+',
        '(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*[^\s,;]+',
        '(?i)\bbearer\s+[a-z0-9._\-]{10,}\b',
        '(?i)\bsk-[a-z0-9]{10,}\b',
        '(?i)-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----'
    )
    foreach ($p in $patterns) {
        $masked = [regex]::Replace($masked, $p, '***REDACTED***')
    }
    return $masked
}

function ConvertTo-CostRedactedRecord {
    param([Parameter(Mandatory)]$Record)
    # Never leaks prompt/raw content; token + cost summary only.
    $usage = $null
    if ($Record.PSObject.Properties.Name -contains 'usage') { $usage = $Record.usage }
    $cost = $null
    if ($Record.PSObject.Properties.Name -contains 'estimated_cost_usd') { $cost = $Record.estimated_cost_usd }
    return [ordered]@{
        redacted            = $true
        run_id              = [string]$Record.run_id
        timestamp_utc       = [string]$Record.timestamp_utc
        provider            = [string]$Record.provider
        model               = [string]$Record.model
        api_calls           = [int]$Record.api_calls
        task_fingerprint    = [string]$Record.task_fingerprint
        usage               = $usage
        estimated_cost_usd  = $cost
        unverified_rate     = [bool]$Record.unverified_rate
        verdict             = [string]$Record.verdict
        budget_decision     = [string]$Record.budget_decision
    }
}

# ---------------------------------------------------------------------------
# Deterministic fingerprint (prompt + context + model) for comparable runs
# ---------------------------------------------------------------------------

function Get-CostRunFingerprint {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Prompt,
        [string[]]$ContextPaths = @(),
        [Parameter(Mandatory)][string]$Model
    )
    $normalizedPrompt = (($Prompt -replace "`r`n", "`n").Trim())
    $paths = @($ContextPaths | ForEach-Object { ($_ -replace '\\', '/').Trim().ToLowerInvariant() } | Sort-Object -Unique)
    $payload = "model=$Model`n" + "prompt=`n$normalizedPrompt`n" + "context=`n" + ($paths -join "`n")
    return (Get-CostSha256 -Text $payload)
}

# ---------------------------------------------------------------------------
# Run record (default: redaction-safe)
# ---------------------------------------------------------------------------

function New-CostRunRecord {
    param(
        [Parameter(Mandatory)][string]$Provider,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)]$Usage,
        $RateTable = $null,
        [string]$RunId = '',
        [string]$TimestampUtc = '',
        [string]$TaskFingerprint = '',
        [int]$ApiCalls = 0,
        [string]$Verdict = 'PENDING',
        [string]$RawResponse = '',
        [double]$BudgetCapUsd = 0,
        [long]$BudgetCapTokens = 0,
        [switch]$IncludeRawResponse
    )
    if (-not $TimestampUtc) { $TimestampUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ') }
    if (-not $RunId) { $RunId = New-CostRunId }

    if ($null -eq $RateTable) {
        try { $RateTable = Get-CostRateTable } catch { $RateTable = $null }
    }
    $est = Invoke-CostEstimate -Usage $Usage -RateTable $RateTable

    # Budget guard against the estimate (tokens + cost)
    $guard = Invoke-CostBudgetGuard -EstimatedCostUsd $est.estimated_cost_usd -TotalTokens $est.usage.total_tokens -CapUsd $BudgetCapUsd -CapTokens $BudgetCapTokens

    $record = [ordered]@{
        run_id             = $RunId
        timestamp_utc      = $TimestampUtc
        provider           = $Provider
        model              = $Model
        api_calls          = $ApiCalls
        task_fingerprint   = $TaskFingerprint
        usage              = $est.usage
        estimated_cost_usd = $est.estimated_cost_usd
        unverified_rate    = $est.unverified_rate
        rate_status        = $est.rate_status
        rate_source        = $est.rate_source
        assumptions        = $est.assumptions
        budget_cap_usd     = $BudgetCapUsd
        budget_cap_tokens  = $BudgetCapTokens
        budget_decision    = $guard.decision
        stop_result        = $guard.stop_result
        verdict            = $Verdict
        # full prompt / raw payload are NOT stored by default (redaction policy)
        prompt_stored      = $false
        raw_response_stored = $false
    }
    if ($IncludeRawResponse) {
        $record.raw_response_stored = $true
        $record.raw_response_redacted = (ConvertTo-CostRedactedText -Text $RawResponse)
    }
    return $record
}

# ---------------------------------------------------------------------------
# Budget guard — preflight + in-run
# ---------------------------------------------------------------------------

function Invoke-CostBudgetPreflight {
    param(
        [double]$CapUsd = 0,
        [long]$CapTokens = 0,
        $RateTable = $null
    )
    if ($null -eq $RateTable) {
        try { $RateTable = Get-CostRateTable } catch { $RateTable = $null }
    }
    $verified = $false
    if ($RateTable -and $RateTable.PSObject.Properties.Name -contains 'verified') {
        $verified = [bool]$RateTable.verified
    }
    $ok = $true
    $reasons = New-Object System.Collections.Generic.List[string]
    if ($CapUsd -le 0 -and $CapTokens -le 0) {
        $ok = $false
        $reasons.Add('no cap configured: set CapUsd and/or CapTokens > 0') | Out-Null
    }
    if ($CapUsd -gt 0 -and -not $verified) {
        $reasons.Add('cost cap depends on UNVERIFIED rate; estimates only, no billing guarantee') | Out-Null
    }
    $decision = 'READY'
    if (-not $ok) { $decision = $script:BudgetBlocked }
    return [ordered]@{
        ok           = $ok
        cap_usd      = $CapUsd
        cap_tokens   = $CapTokens
        rate_verified = $verified
        reasons      = @($reasons)
        decision     = $decision
    }
}

function Invoke-CostBudgetGuard {
    param(
        [double]$EstimatedCostUsd = 0,
        [long]$TotalTokens = 0,
        [double]$CapUsd = 0,
        [long]$CapTokens = 0
    )
    $exceeded = $false
    $reasons = New-Object System.Collections.Generic.List[string]
    if ($CapUsd -gt 0 -and $EstimatedCostUsd -gt $CapUsd) {
        $exceeded = $true
        $reasons.Add("cost_usd=$EstimatedCostUsd > cap_usd=$CapUsd") | Out-Null
    }
    if ($CapTokens -gt 0 -and $TotalTokens -gt $CapTokens) {
        $exceeded = $true
        $reasons.Add("total_tokens=$TotalTokens > cap_tokens=$CapTokens") | Out-Null
    }
    $decision = $script:BudgetAllowed
    $stopResult = $null
    if ($exceeded) {
        $decision = $script:BudgetExceeded
        $stopResult = $script:BudgetExceeded
    }
    return [ordered]@{
        decision      = $decision
        stop_result   = $stopResult
        exceeded      = $exceeded
        reasons       = @($reasons)
        actual_cost_usd = $EstimatedCostUsd
        actual_total_tokens = $TotalTokens
    }
}

# ---------------------------------------------------------------------------
# Billing reconciliation (human enters billed amounts; agent never touches billing)
# ---------------------------------------------------------------------------

function Test-CostBillingVariance {
    param(
        [double]$LocalUsd,
        [double]$BilledUsd,
        [double]$TolerancePct = 20.0
    )
    $variancePct = $null
    if ($LocalUsd -gt 0) {
        $variancePct = [Math]::Round((($BilledUsd - $LocalUsd) / $LocalUsd) * 100.0, 2)
    }
    $within = $null
    if ($null -ne $variancePct) {
        $within = ([Math]::Abs([double]$variancePct) -le $TolerancePct)
    }
    return [ordered]@{
        local_usd           = $LocalUsd
        billed_usd          = $BilledUsd
        variance_pct        = $variancePct
        tolerance_pct       = $TolerancePct
        within_tolerance    = $within
        note                = 'billed_usd is human-entered from provider billing; agent never accesses billing accounts'
    }
}

$script:CostTelemetryLoaded = $true
