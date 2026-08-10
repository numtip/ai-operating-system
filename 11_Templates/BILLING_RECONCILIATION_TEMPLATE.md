# Billing Reconciliation Template — Stage 2A

> Purpose: compare **local run telemetry** (this repo) against **provider billing**.
> The agent never opens billing accounts, never scrapes the portal, and never
> records raw credentials or header payloads. A human fills `billed_usd`.

## Instructions

1. Keep each run's evidence in the Stage 2A evidence file.
2. Human: copy the billed USD for the billing period from the provider portal.
3. Run the variance helper (below) and paste the output into the evidence file.
4. If variance exceeds `tolerance_pct`, open a remediation note — do not silently accept.

## Variance helper

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command `
  ". 'prompt-compiler/runtime/Cost-Telemetry.ps1';" `
  "Test-CostBillingVariance -LocalUsd <local_telemetry_usd> -BilledUsd <billed_usd> -TolerancePct 20"
```

## Template record

```json
{
  "schema_version": "1.0",
  "provider": "deepseek",
  "model": "deepseek-v4-flash",
  "billing_period": "YYYY-MM-DD..YYYY-MM-DD",
  "run_ids": ["run-...", "run-...", "run-..."],
  "local_telemetry_usd": null,
  "billed_usd": null,
  "variance_pct": null,
  "tolerance_pct": 20,
  "within_tolerance": null,
  "rate_status": "UNVERIFIED_RATE",
  "rate_source": null,
  "filled_by_human_at": null,
  "note": "agent never accesses billing accounts; billed_usd is human-entered"
}
```

## Hard rules

- Do not fabricate billed amounts; leave `null` until a human fills them.
- Do not log provider credentials, request headers, or account identifiers.
- Cost figures stay `UNVERIFIED_RATE` until `rate-table.json` is verified.
