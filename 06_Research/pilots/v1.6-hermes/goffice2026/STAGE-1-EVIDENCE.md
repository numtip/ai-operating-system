# GOFFICE2026 Pilot — Stage 1 Evidence (SIMULATED)

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Authorization:** Stage 1 only — reversible local compatibility spike using a **stub/simulated adapter boundary**.
**Honesty label:** ALL results are SIMULATED compatibility evidence. This stub is NOT Hermes; it did not invoke Hermes, MCP, any API, a browser, credentials, or external tools. No production safety or actual Hermes compatibility is claimed from this test.

## 1. What was implemented

- `stub/Stub-Adapter.ps1` — local, non-networked, deterministic PowerShell simulation of the `HERMES_ADAPTER_CONTRACT.md` boundary:
  - `New-StubTask` — governed task contract constructor (all §2 fields)
  - `Test-StubApproval` — L0-L4 approval semantics incl. task/policy binding, expiry, anti-replay (§5)
  - `Test-StubScope` — tool/credential scope enforcement (§6)
  - `Test-StubContext` — context handoff immutability + deviation detection (§4)
  - `Invoke-StubRuntime` — simulated execution (deterministic payload hash, no side effects)
  - `New-StubAudit` — §10 audit record
  - `Invoke-StubAdapter` — main boundary entry (completeness → idempotency → approval → scope → context → failure injection → execution → audit)
- `stub/run-stage1.ps1` — 13-scenario runner; in-memory idempotency/audit store; writes `STAGE-1-RESULTS.json`.

**Reversibility / cleanup:** stub writes nothing outside `06_Research/pilots/v1.6-hermes/`; state is in-memory per run; removing the `stub/` directory fully reverts. No install, registry, PATH, service, or network change.

## 2. Reproduction commands

```powershell
# 1. (Optional) confirm Stage 0 baseline hash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compile-prompt.ps1 `
  -Project goffice2026 -Goal "Read-only audit" -ModelProfile deepseek-v4-flash -OutputMode json

# 2. Run the Stage 1 spike (evidence → 06_Research/pilots/v1.6-hermes/goffice2026/STAGE-1-RESULTS.json)
powershell -NoProfile -ExecutionPolicy Bypass -File `
  06_Research/pilots/v1.6-hermes/stub/run-stage1.ps1

# 3. Re-run for determinism check (idempotency store resets per run; same results expected)
```

Inputs per scenario: `New-StubTask` with the 8-file Stage 0 mandatory context (`01_Projects/goffice2026/ADAPTER.md`, `07_Memory/{CURRENT_STATE,OPERATING_RULES,SYSTEM_MEMORY}.md`, `12_Indexes/project_index.json`, `external:doc:goffice2026/{package.json,PRODUCT.md,README.md}`), governance policy `ADR-0013+v4-2026-08-09`, model scope `deepseek-v4-flash`.

## 3. Scenario results (13/13 PASS)

| # | Scenario | Expected | Actual | Result | Key evidence |
|---|---|---|---|---|---|
| T01 | Normal L0 read | success, 8 context files preserved | success | PASS | file parity 8/8 with Stage 0; stub context hash `a7f846e3…` vs compiler `ad907c27…` — different methodology (list hash vs full-output hash), documented, not a regression |
| T02 | Normal L1 analyze | success | success | PASS | L1 auto per policy |
| T03 | Approval denied (L3, no approval) | needs_approval | needs_approval | PASS | "level L3 requires human approval; none attached" |
| T04 | Approval expired | expired | expired | PASS | expiry `2020-01-01` honored |
| T05 | Approval replay (wrong task) | rejected | rejected | PASS | anti-replay: record not bound to task_id |
| T06 | Retry / idempotency | 2nd call → idempotent echo | success, `idempotent=true` | PASS | payload hash `773a5441…` echoed identically; no duplicate side effect |
| T07 | Tool scope violation | aborted | aborted | PASS | hard stop on tool outside `approved_tool_scope` |
| T08 | Credential-scope violation | aborted | aborted | PASS | no credential resolved outside task `credential_ref` |
| T09 | Context deviation | aborted + deviation reported | aborted | PASS | deviation `03_Architecture/ROADMAP.md` flagged |
| T10 | Tool failure → retry | first failed(retryable), retry success | same | PASS | transient failure classified retryable; retry succeeds |
| T11 | Non-retryable failure | failed(retryable=false) → human review | same | PASS | escalation path per §7 |
| T12 | Runtime crash → recovery | crash failed(retryable), retry reconciled | same | PASS | no orphan mutations; reconciliation via same key |
| T13 | Rollback/fallback | audit preserved; manual path = Stage 0 tools | success + audit | PASS | rollback plan §3-§7 semantics; fallback = existing `check-bootstrap.ps1`/`compile-prompt.ps1` |

## 4. Manual-baseline comparison (Stage 0 → Stage 1 stub)

| Metric | Stage 0 (manual) | Stage 1 (stub) | Delta |
|---|---|---|---|
| Context files | 8 | 8 | 0 (parity) |
| Task success rate | 1/1 (100%) | 13/13 (100%) | 0 |
| Auditability | 1/1 (100%) | 12/13 records (T06 duplicate suppressed by design → 100% of executed tasks) | n/a |
| Governance regression | 0 | 0 (all gate checks enforced) | 0 |
| Cost | 0 (no model) | 0 (simulated) | 0 |
| Operator effort | 3 steps (read/compile/validate) | +2 steps (run spike, inspect JSON) | +2 |
| Latency | 575 ms (compile) | ms-range per task (simulated) | not comparable (different workloads) |

## 5. Explicit limitations of stub evidence

1. **Not Hermes runtime validation** — stub implements the contract, not Hermes internals. Hermes may behave differently (transport, native error taxonomy, scheduling, real tools).
2. **No real tools/credentials/network** — execution was a deterministic hash echo; real tool invocation semantics untested.
3. **Single-run, in-memory state** — idempotency/audit store resets per run; durability/restart semantics untested.
4. **No L4 approved-path success** tested (only rejection paths) — L4 positive execution requires real owner approval evidence.
5. **Rollback simulated at contract level** — real rollback requires the (future) Hermes install + `HERMES_ROLLBACK_PLAN.md` §3-§7 execution.
6. These results support an **owner review** of contract completeness, NOT a claim of production safety or Hermes readiness.

## 6. Audit sample (T01, §10 fields)

| Field | Value |
|---|---|
| task_id | `goffice2026-s1-t01` |
| actor | `ai-os-agent-simulated` |
| project_id | goffice2026 |
| context_package_version | `a7f846e3…` (stub list-hash; see limitation note) |
| governance_policy_version | ADR-0013+v4-2026-08-09 |
| data_classification | public/internal |
| runtime_version | `stub-v0.1.0-simulated` |
| model_provider | deepseek-v4-flash |
| tools_used | read-adapter, read-index, read-canonical |
| approval_status | auto (L0) |
| status | success |
| simulated | true |
