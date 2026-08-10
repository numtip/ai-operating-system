# STAGE 2A — Cost Observability + Budget-Stop Evidence

**Date:** 2026-08-10
**Branch:** `evidence/stage-2a-cost-controls`
**Baseline:** `origin/main @ 7a05f709`
**Verdict:** `STAGE_2A_DIRECT_API_PASS_WITH_BILLING_WAIVER` (direct DeepSeek API evidence complete; billing reconciliation waived by owner for this bounded pilot)

---

## Summary

Cost-telemetry + budget-guard controls implemented (no secrets in repo), pre-key
hardening done (external secret loader), and the **3-comparable-run LIVE protocol was
executed** against the DeepSeek API (owner-confirmed key) under caps — all 3 runs
`ALLOW`, deterministic, ~6s total. Stop behavior (`BUDGET_EXCEEDED`) proven
deterministically in tests + mock evidence (live runs stayed under cap, so no stop
was triggered — correct behavior).

## Live run results (2026-08-10, real DeepSeek API)

| Run | Mode | Input | Output | Total tok | Est. cost | Decision |
|-----|------|-------|--------|-----------|-----------|----------|
| 1 | LIVE | 90 | 10 | 100 | $0.0000353 | ALLOW |
| 2 | LIVE | 90 | 11 | 101 | $0.0000364 | ALLOW |
| 3 | LIVE | 90 | 19 | 109 | $0.0000452 | ALLOW |

Task: synthetic AI-OS-internal (no target-project data). Fingerprint stable across
runs: `9e131246…`. Caps: model `deepseek-v4-flash`, cap_usd `0.02`,
cap_total_tokens `500000`, max_output_tokens `2000`. Rate status `UNVERIFIED_RATE`
(no confirmed pricing source; estimates only). Evidence: `STAGE-2A-LIVE-EVIDENCE.json`.

## Implementation

| File | Purpose |
|------|---------|
| `prompt-compiler/runtime/Cost-Telemetry.ps1` | run ID, timestamp, provider/model, token usage, estimated cost, budget guard (preflight + in-run), redaction, fingerprint, billing variance |
| `prompt-compiler/runtime/Secret-Loader.ps1` | external secret loader (`%LOCALAPPDATA%\AI-OS\stage2a.env`) + value-safe preflight + leak scan |
| `prompt-compiler/runtime/stage2a-run-config.json` | model/caps/max_output_tokens (no secrets) |
| `prompt-compiler/runtime/Invoke-DeepSeekCall.ps1` | single bounded API call (child process; key read only here; never logged) |
| `prompt-compiler/runtime/Invoke-Stage2aLiveRun.ps1` | 3-run orchestrator, cap-enforced, evidence writer |
| `prompt-compiler/runtime/rate-table.json` | per-MTok rates marked `UNVERIFIED_RATE` |
| `prompt-compiler/fixtures/mock-provider-response.json` | synthetic usage for tests |
| `prompt-compiler/tests/run-tests-stage2a.ps1` | 37 deterministic tests |
| `prompt-compiler/tests/run-tests-stage2a-hardening.ps1` | 16 hardening/preflight tests |
| `06_Research/pilots/v1.6-hermes/STAGE-2A-RUNBOOK.md` | protocol + live-run gate + checklist |
| `06_Research/pilots/v1.6-hermes/schemas/run-evidence.schema.json` | evidence JSON schema |
| `06_Research/pilots/v1.6-hermes/STAGE-2A-MOCK-EVIDENCE.json` | 3-run MOCK evidence (stop behavior) |
| `06_Research/pilots/v1.6-hermes/STAGE-2A-LIVE-EVIDENCE.json` | 3-run LIVE evidence |
| `11_Templates/BILLING_RECONCILIATION_TEMPLATE.md` | local-vs-billing variance template |
| `.env.example` | committable template (no values); secrets live outside repo |

### Required Stage 2A controls — status

| Control | Status |
|---------|--------|
| a. run ID + timestamp + provider/model + input/output/total tokens | ✅ `New-CostRunRecord` (tests 1–2; live usage recorded) |
| b. estimated cost with assumptions + rate source | ✅ `Invoke-CostEstimate`; `UNVERIFIED_RATE` until rate verified (test 3) |
| c. per-run configurable budget cap (USD + tokens) | ✅ `Invoke-CostBudgetPreflight` / `Invoke-CostBudgetGuard` (test 4) |
| d. preflight + in-run stop `BUDGET_EXCEEDED` | ✅ boundary-exact tests; mock stop evidence; live under cap → ALLOW |
| e. redaction — no secret / full prompt by default | ✅ `prompt_stored=false`, `raw_response_stored=false`, masking (test 7) |
| f. secret isolation — external file only, no repo `.env`, no log | ✅ `Secret-Loader`; preflight leak scan; hardening tests |

## Test results

- `run-tests-stage2a.ps1` — **37/37 PASS**
- `run-tests-stage2a-hardening.ps1` — **16/16 PASS**
- Cap boundary + `BUDGET_EXCEEDED` covered (tests 5–6; hardening 5a–5e).

## 3-run protocol status

| Run | mode | status |
|-----|------|--------|
| 1 | LIVE | DONE — ALLOW |
| 2 | LIVE | DONE — ALLOW |
| 3 | LIVE | DONE — ALLOW |

## Billing reconciliation — WAIVED (owner decision 2026-08-10)

The owner has explicitly **waived billing reconciliation** for this limited Direct
DeepSeek API pilot. No `billed_usd` will be filled, no rate will be set
`verified:true`, and `Test-CostBillingVariance` will not be run for Stage 2A Direct
API. Billing portal / API / key are not accessed.

- **Reason:** bounded low-cost pilot; cost caps and fail-closed preflight already verified.
- **Scope:** Stage 2A Direct API only.
- **Limitations:**
  - This is **not** a provider-billed cost proof — estimates remain `UNVERIFIED_RATE`.
  - Does **not** cover Hermes/VPS or any other runtime.
- **Recorded in evidence:** `billing_waiver` object (`waived: true` + reason/scope/
  limitations/approved_by/approved_at_utc) in `STAGE-2A-LIVE-EVIDENCE.json` and
  `STAGE-2A-API-KEY-VALIDATION.json`; MOCK evidence explicitly `billing_waiver: null`.
- **Default policy unchanged:** `Test-CostReconciliationReadiness` still `BLOCKED` while
  the rate is unverified or `billed_usd` is null — the waiver is an explicit,
  evidence-recorded owner decision, not a silent bypass.

**Next gate:** Hermes local integration is a separate workstream (not this pilot).

## Gates

| Gate | Result |
|------|--------|
| `scripts/validate-indexes.ps1` | PASS |
| `prompt-compiler/tests/run-tests.ps1` | PASS 53/53 |
| `prompt-compiler/tests/run-tests-stage2a.ps1` | PASS 37/37 |
| `prompt-compiler/tests/run-tests-stage2a-hardening.ps1` | PASS 16/16 |
| `scripts/check-bootstrap.ps1` | PASS 5/5 |
| `git diff --check` | PASS |
| targeted secret scan (`main...HEAD`) | PASS |

## Confirmed untouched

VPS, Docker, Cloudflare, DNS, production, publish, GOFFICE2026, Document Center,
RAE, M365/SharePoint, GitHub Pages — **none modified**. No Hermes install/upgrade,
no `.env` in repo, no key committed/displayed. No commit/push to `main`.
Billing account was never accessed.
