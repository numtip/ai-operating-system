# Billing Reconciliation Template — Stage 2A

> Purpose: compare **local run telemetry** (this repo) against **provider billing**.
> The agent never opens billing accounts, never scrapes the portal, and never
> records raw credentials or header payloads. A human fills `billed_usd`.

## Instructions

1. Keep each run's evidence in the Stage 2A evidence file.
2. Human: in DeepSeek billing, locate the **billing period** that covers the 4 request
   timestamps below, and copy the **total billed USD for exactly those 4 requests**
   (3 comparable live runs + 1 API-key validation) — not the whole account period.
3. Record the billing period (`start_utc`..`end_utc`) you matched, and per-request the
   provider request ID if DeepSeek exposes it (`provider_request_id`), to tie each
   line item to local telemetry. Never paste the API key or request payloads.
4. Run the readiness gate; only when it reports `READY` run the variance helper
   (below) and paste the output into the evidence file.
5. If variance exceeds `tolerance_pct`, open a remediation note — do not silently accept.

## Requests to match (4 total — IDs are local hashes; match on timestamps)

| # | Request | Local run_id | timestamp_utc | provider_request_id (owner fills) |
|---|---------|--------------|---------------|-----------------------------------|
| 1 | LIVE run 1 | `run-9d1a814765d407ef` | `2026-08-10T03:24:59Z` | |
| 2 | LIVE run 2 | `run-2f319a6468e77020` | `2026-08-10T03:25:00Z` | |
| 3 | LIVE run 3 | `run-52779501816467c7` | `2026-08-10T03:25:02Z` | |
| 4 | API-key validation | *(no local id)* | `2026-08-10T03:31:50Z` | |

## Readiness gate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command `
  ". 'prompt-compiler/runtime/Cost-Telemetry.ps1';" `
  "Test-CostReconciliationReadiness -BilledUsd <billed_usd_or_null>"
# BLOCKED until: rate-table verification_status = VERIFIED AND billed_usd is not null.
```

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
  "billing_period": { "start_utc": "YYYY-MM-DDTHH:MM:SSZ", "end_utc": "YYYY-MM-DDTHH:MM:SSZ" },
  "requests": [
    { "kind": "live_run", "local_run_id": "run-...", "timestamp_utc": "...", "provider_request_id": null },
    { "kind": "api_key_validation", "local_run_id": null, "timestamp_utc": "...", "provider_request_id": null }
  ],
  "local_telemetry_usd": null,
  "billed_usd": null,
  "variance_pct": null,
  "tolerance_pct": 20,
  "within_tolerance": null,
  "rate_status": "UNVERIFIED_RATE",
  "verification_status": "UNVERIFIED",
  "rate_source": null,
  "rate_source_url": null,
  "retrieved_at_utc": null,
  "currency": "USD",
  "price_basis": "per_1M_tokens",
  "effective_date": null,
  "filled_by_human_at": null,
  "note": "agent never accesses billing accounts; billed_usd is human-entered"
}
```

## Hard rules

- Do not fabricate billed amounts; leave `null` until a human fills them.
- Do not log provider credentials, request headers, or account identifiers.
- Cost figures stay `UNVERIFIED_RATE` until `rate-table.json` is verified against an
  official pricing page (`verification_status` = `UNVERIFIED` until then).
- Reconciliation (`Test-CostBillingVariance`) must not run while rate is unverified
  or `billed_usd` is null — `Test-CostReconciliationReadiness` blocks it.
