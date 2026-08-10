# STAGE 2A — Comparable-Run Protocol (Runbook)

**Status:** MOCK evidence complete; LIVE run requires human confirmation
**Date:** 2026-08-10
**Branch:** `evidence/stage-2a-cost-controls`
**Schema:** `schemas/run-evidence.schema.json`
**Telemetry:** `prompt-compiler/runtime/Cost-Telemetry.ps1` (no LLM, no network)

> Purpose: 3 comparable L0/L1 read-only runs with reconciled cost evidence, enforcing
> Stage 2 exit criteria from Blueprint V4.1 §9 ("three comparable runs with reconciled
> metrics and stop behavior").

---

## 1. Run contract (fixed across all 3 runs)

| Field | Value |
|-------|-------|
| Task | identical task text (see below) |
| Model | `deepseek-v4-flash` |
| Prompt/context fingerprint | `Get-CostRunFingerprint` SHA-256 (deterministic) |
| Cap | per-run `cap_usd` + `cap_total_tokens`, identical for all runs |
| Mode | L0/L1 read-only audit only |
| Rate status | `UNVERIFIED_RATE` until a confirmed provider rate source is recorded |

Every run must produce a record shaped by `New-CostRunRecord` and must end with a
`budget_decision` of `ALLOW` (or `BUDGET_EXCEEDED` + `stop_result` if the cap trips —
that is itself a valid stop-behavior evidence).

## 2. Acceptance tolerance

- Same task, same model, same fingerprint, same cap across all 3 runs.
- Local-vs-provider-billing variance must stay within `tolerance_pct` (default 20%).
- Token totals must be deterministic or within a documented noise band.
- `stop_result == BUDGET_EXCEEDED` must appear when a cap is intentionally set below
  the run's actual cost/tokens (stop-behavior proof).

## 3. How to reconcile with provider billing

1. Keep the local evidence file (this repo) as the source of run telemetry.
2. Do **not** let the agent open the billing account or scrape the portal.
3. A human copies the billed amount into `billing_reconciliation.billed_usd`.
4. Run `Test-CostBillingVariance -LocalUsd <sum> -BilledUsd <human value> -TolerancePct 20`
   and record `variance_pct` + `within_tolerance` in the evidence file.

## 4. Live-run gate (human confirmation required)

A live run is allowed **only** when **all** hold:

- [ ] Preflight `Invoke-Stage2aPreflight` passes: external secret file
      `%LOCALAPPDATA%\AI-OS\stage2a.env` exists, `DEEPSEEK_API_KEY` non-empty
      (value never read/printed by AI), no key leak in repo/diff/evidence/logs,
      run config (model `deepseek-v4-flash`, `cap_usd`, `cap_total_tokens`,
      `max_output_tokens`) is set. Run with:
      `powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests-stage2a-hardening.ps1`
- [ ] Secrets are loaded only via `prompt-compiler/runtime/Secret-Loader.ps1`
      from the external file when spawning the child process; never logged.
- [ ] No sensitive/target-project data is sent; task is a synthetic or AI-OS-internal
      L0/L1 read-only task.
- [ ] Per-run caps are set; `BUDGET_EXCEEDED` stop behavior is exercised on run N.

Approval record (owner fills): ____________________________

If the confirmation is not granted, produce **MOCK evidence + this checklist** and the
stage verdict is `STAGE_2A_PARTIAL` (done — see `STAGE-2A-MOCK-EVIDENCE.json`).

## 5. MOCK mode evidence steps (already executed 2026-08-10)

1. Load `prompt-compiler/fixtures/mock-provider-response.json` (synthetic usage).
2. Build 3 run records with `New-CostRunRecord` using the same task fingerprint, same
   cap, deterministic run IDs.
3. Assert each record: tokens, estimate, `UNVERIFIED_RATE` flag, budget decision.
4. Assert redaction: no prompt/raw payload stored by default.
5. Emit `STAGE-2A-MOCK-EVIDENCE.json`; human fills billing section later.

## 6. Human checklist after MOCK (owner)

- [ ] Verify rate table `prompt-compiler/runtime/rate-table.json` against provider docs;
      flip `verified: true` and update `rate_source` only with a confirmed source.
- [ ] Fill `billing_reconciliation` with a real billed amount for the 3 comparable runs.
- [ ] Re-run `Test-CostBillingVariance` and record the result.
- [ ] Decide whether to approve a LIVE 3-run protocol (section 4).
