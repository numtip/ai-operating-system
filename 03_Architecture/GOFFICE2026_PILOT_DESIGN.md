# GOFFICE2026 Governed Pilot Execution Design

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Status:** Design v0.1 — no install, no execution. Installation and any production mutation are separate human-approval gates.
**Pilot:** GOFFICE2026 (Blueprint V4 §16 reference pilot; existing project adapter: `01_Projects/goffice2026/ADAPTER.md`).

## 1. Scope and non-goals

### In scope
- Validate the governed task contract + adapter contract (`HERMES_ADAPTER_CONTRACT.md`) end-to-end on one low-risk project.
- Read-only execution first: context retrieval, prompt compilation, quality gate, task orchestration on read tasks.
- Measure context size, task success, latency, cost, auditability, operator effort (ADR-0013 metrics).
- Capture evidence and audit records in repo.

### Non-goals (STOP)
- No Hermes installation until the install gate (§9) is explicitly passed.
- No production mutation, deploy, DNS, secrets change, or VPS action.
- No write-back to GOFFICE2026 external repo beyond approved read/task evidence.
- No replacing AI-OS Control Plane capabilities (RETAIN set per `HERMES_CAPABILITY_MATRIX.md`).
- No auto-promotion of Hermes to default runtime (pilot evidence required first).

## 2. Read-only first stage

Stage 0 (mandatory) — Hermes not installed; validates AI-OS side of the contract:

- Bootstrap gate + mandatory context retrieval for GOFFICE2026.
- Prompt compile + quality gate on real project context.
- Produce a governed task contract instance (fields per adapter contract §2) for read-only tasks.
- Baseline measurements (see §5) captured on the manual path.

Stage 1 — reversible compatibility spike (install-gated):
- Hermes runs the same read-only tasks through the adapter; compare against Stage 0 baselines.
- Rollback exercised per `HERMES_ROLLBACK_PLAN.md`.

## 3. Task contract and approval levels

Every pilot task carries the governed task contract fields (adapter contract §2) including `task_id`, `idempotency_key`, `execution_level`, `data_classification`, `credential_ref`, budget.

Approval levels applied (Blueprint V4 §11):

| Level | Pilot operation | Default |
|---|---|---|
| L0 | Read project context / indexes | Automatic |
| L1 | Analyze / plan / recommend (read-only) | Automatic |
| L2 | Write task evidence to repo pilot logs | Policy-controlled |
| L3 | Any external mutation / publish | Human approval required (not exercised in pilot unless approved) |
| L4 | Secrets / destructive / production | Explicitly out of pilot scope |

## 4. Success metrics with measurable baselines

Baseline = Stage 0 (manual path) on the same task set. Success = pilot meets or improves with no governance regression.

| Metric | Definition | Baseline source |
|---|---|---|
| Context size (tokens/bytes) | Size of compiled context package per task | Stage 0 compile output |
| Task success rate | Successful / total tasks with validation pass | Stage 0 runs |
| Latency | Task start → validated result | Stage 0 timestamps |
| Cost | Token/cost per task where available | Stage 0 model profile |
| Auditability | 100% tasks have complete audit record (all §10 fields) | Contract check |
| Operator effort | Manual steps per task (count) | Stage 0 run notes |
| Governance regression | Any bypass of bootstrap/quality/approval gates | Gate logs |

Target: context size ≤ baseline +20%; success rate ≥ baseline; auditability = 100%; zero gate bypass.

## 5. Failure injection / recovery tests

Design-time definitions (executed only in the install-gated spike):

- **Tool failure:** inject a tool call error; verify failure semantics (retryable vs non-retryable) and no duplicate side effects (idempotency).
- **Approval timeout:** task reaching L2/L3 without approval; verify `needs_approval` path and expiry.
- **Context deviation:** runtime attempts to use unapproved context; verify deviation is reported and task aborts.
- **Credential-scope violation:** runtime attempts a tool outside `approved_tool_scope`; verify hard stop.
- **Runtime crash mid-task:** verify state recovery, no orphaned mutations, task retry/reconciliation.
- **Rollback:** execute `HERMES_ROLLBACK_PLAN.md` §3-§7; verify clean revert to Stage 0 baseline.

## 6. Evidence and audit outputs

Per task (persisted to repo, e.g. `06_Research/pilots/v1.6-hermes/goffice2026/`):

- Governed task contract instance (JSON/MD).
- Execution evidence (status, timestamps, tools, model, metrics).
- Validation results (bootstrap + quality gate).
- Audit record (adapter contract §10 fields).
- Deviation/failure records when applicable.
- Session summary following `07_Memory/sessions/` convention.

## 7. Human gates

Gate A — **Install gate:** before any Hermes installation, explicit owner approval required, plus: rollback plan reviewed, pre-install snapshot taken, secrets/production/DNS/VPS confirmed untouched.

Gate B — **Production-mutation gate:** before any L3+ operation on GOFFICE2026 or infrastructure, separate explicit owner approval required; not authorized by this document.

Neither gate is implied by this design.

## 8. Exit criteria for the pilot

- Stage 0 baselines captured.
- Adapter contract exercised with zero governance bypass.
- All §5 recovery tests pass in the spike (or documented deviations with owner note).
- Auditability = 100% for pilot tasks.
- Metrics report written comparing pilot vs baseline.
- Recommendation recorded (continue / adjust / stop) for ADR decision on Hermes default runtime.

## 9. References

- `HERMES_ADAPTER_CONTRACT.md` (this directory)
- `HERMES_CAPABILITY_MATRIX.md`
- `HERMES_ROLLBACK_PLAN.md`
- `AI_OPERATING_SYSTEM_BLUEPRINT_V4.md` §16 (reference pilot)
- `04_ADR/ADR-0013-integration-first-hermes-runtime.md`
- `01_Projects/goffice2026/ADAPTER.md`
