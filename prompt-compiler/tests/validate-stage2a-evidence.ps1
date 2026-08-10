<#
.SYNOPSIS
  Deterministic schema-contract validation for Stage 2A evidence files.
  Validates LIVE, MOCK, and API-KEY-VALIDATION evidence against the schema
  contract (structural checks; no external JSON-Schema dependency), plus the
  redaction invariant: no raw task/prompt text in any evidence file.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/validate-stage2a-evidence.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = [string](Resolve-Path (Join-Path $PSScriptRoot '../..'))
$pilot = Join-Path $Root '06_Research/pilots/v1.6-hermes'

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

function Read-Evidence {
    param([Parameter(Mandatory)][string]$RelPath)
    $full = Join-Path $pilot $RelPath
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "missing evidence: $RelPath"
    }
    return ([System.IO.File]::ReadAllText($full) | ConvertFrom-Json)
}

$rawPromptPatterns = @('Reply with the single token', 'Audit AI-OS v1.6 Stage 2A telemetry contract')

# --- schema contract itself ---
$schema = Get-Content (Join-Path $pilot 'schemas/run-evidence.schema.json') -Raw | ConvertFrom-Json
$protoReq = @($schema.properties.protocol.required)
Assert-True '0a.schema_requires_task_class' ($protoReq -contains 'task_class') ("required=$($protoReq -join ',')")
Assert-True '0b.schema_does_not_require_task' ($protoReq -notcontains 'task') ("required=$($protoReq -join ',')")
Assert-True '0c.schema_cap_has_max_output' ($schema.properties.cap.properties.PSObject.Properties.Name -contains 'max_output_tokens')
Assert-True '0d.schema_declares_stopped_early' ($schema.properties.PSObject.Properties.Name -contains 'stopped_early')
Assert-True '0e.schema_declares_redaction' ($schema.properties.PSObject.Properties.Name -contains 'redaction')

# --- LIVE evidence ---
$live = Read-Evidence 'STAGE-2A-LIVE-EVIDENCE.json'
Assert-True '1a.live_schema_version' ($live.schema_version -eq '1.0')
Assert-True '1b.live_protocol_task_class' ([string]$live.protocol.task_class -eq 'synthetic_api_key_validation') "task_class=$($live.protocol.task_class)"
Assert-True '1c.live_protocol_no_task_field' (-not $live.protocol.PSObject.Properties.Name.Contains('task'))
Assert-True '1d.live_mode_live' ($live.protocol.mode -eq 'LIVE')
Assert-True '1e.live_fingerprint' (-not [string]::IsNullOrWhiteSpace([string]$live.task_fingerprint))
Assert-True '1f.live_cap_set' ([double]$live.cap.cap_usd -gt 0 -and [long]$live.cap.cap_total_tokens -gt 0 -and [int]$live.cap.max_output_tokens -gt 0)
Assert-True '1g.live_three_runs' (@($live.runs).Count -eq 3)
$liveRunReq = $true
foreach ($r in @($live.runs)) {
    foreach ($f in @('run_id','timestamp_utc','api_calls','usage','estimated_cost_usd','budget_decision','verdict')) {
        if (-not $r.PSObject.Properties.Name.Contains($f)) { $liveRunReq = $false }
    }
    if ($r.usage.PSObject.Properties.Name -notcontains 'total_tokens') { $liveRunReq = $false }
}
Assert-True '1h.live_run_required_fields' $liveRunReq
Assert-True '1i.live_stop_metadata' ($live.PSObject.Properties.Name.Contains('stopped_early') -and $live.PSObject.Properties.Name.Contains('stop_reason') -and $live.PSObject.Properties.Name.Contains('redaction'))
Assert-True '1j.live_billing_null' ($null -eq $live.billing_reconciliation.billed_usd)
Assert-True '1k.live_no_raw_prompt' (-not (([System.IO.File]::ReadAllText((Join-Path $pilot 'STAGE-2A-LIVE-EVIDENCE.json'))) -match ($rawPromptPatterns -join '|')))

# --- MOCK evidence ---
$mock = Read-Evidence 'STAGE-2A-MOCK-EVIDENCE.json'
Assert-True '2a.mock_schema_version' ($mock.schema_version -eq '1.0')
Assert-True '2b.mock_protocol_task_class' ([string]$mock.protocol.task_class -eq 'synthetic_telemetry_contract') "task_class=$($mock.protocol.task_class)"
Assert-True '2c.mock_protocol_no_task_field' (-not $mock.protocol.PSObject.Properties.Name.Contains('task'))
Assert-True '2d.mock_mode_mock' ($mock.protocol.mode -eq 'MOCK')
Assert-True '2e.mock_three_runs' (@($mock.runs).Count -eq 3)
$mockRunReq = $true
foreach ($r in @($mock.runs)) {
    foreach ($f in @('run_id','timestamp_utc','api_calls','usage','estimated_cost_usd','budget_decision','verdict')) {
        if (-not $r.PSObject.Properties.Name.Contains($f)) { $mockRunReq = $false }
    }
}
Assert-True '2f.mock_run_required_fields' $mockRunReq
Assert-True '2g.mock_billing_null' ($null -eq $mock.billing_reconciliation.billed_usd)
Assert-True '2h.mock_no_raw_prompt' (-not (([System.IO.File]::ReadAllText((Join-Path $pilot 'STAGE-2A-MOCK-EVIDENCE.json'))) -match ($rawPromptPatterns -join '|')))

# --- API-KEY-VALIDATION evidence (standalone schema) ---
$akv = Read-Evidence 'STAGE-2A-API-KEY-VALIDATION.json'
Assert-True '3a.akv_schema_version' ($akv.schema_version -eq '1.0')
Assert-True '3b.akv_check' ($akv.check -eq 'api_key_validation')
Assert-True '3c.akv_has_required' ($akv.PSObject.Properties.Name.Contains('api_key_valid') -and $akv.PSObject.Properties.Name.Contains('http_outcome_class') -and $akv.PSObject.Properties.Name.Contains('provider') -and $akv.PSObject.Properties.Name.Contains('model'))
Assert-True '3d.akv_model_flash' ($akv.model -eq 'deepseek-v4-flash')
Assert-True '3e.akv_no_key_no_prompt' (-not (([System.IO.File]::ReadAllText((Join-Path $pilot 'STAGE-2A-API-KEY-VALIDATION.json'))) -match 'sk-[a-zA-Z0-9]{10,}|Reply with the single token|authorization|bearer'))

Write-Host ''
Write-Host ("STAGE-2A-EVIDENCE-SCHEMA SUMMARY passed={0} failed={1}" -f $passed, $failed)
if ($failed -gt 0) { exit 1 } else { exit 0 }
