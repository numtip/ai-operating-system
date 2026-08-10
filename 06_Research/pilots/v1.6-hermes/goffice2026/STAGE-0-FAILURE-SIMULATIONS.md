# GOFFICE2026 Pilot — Stage 0 Failure-Injection Simulations

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Scope note:** Document/design-level simulations only. No Hermes runtime invoked, no mutation of any runtime, repo, service, credential, cloud resource, or production environment. These are **paper checks** of the contract-defined response, not real runtime validation (per authorization).

Method: for each recovery design in `GOFFICE2026_PILOT_DESIGN.md` §5, verify (a) the AI-OS-side contract defines the correct response, (b) Stage 0 can observe the trigger without runtime, (c) what Stage 1 must actually exercise.

## Simulation matrix

| # | Recovery design | Simulated outcome (contract-defined) | Contract source | Stage 0 observation | Real-spike requirement (Stage 1) |
|---|---|---|---|---|---|
| S1 | Tool failure | Failure classified retryable vs non-retryable; no duplicate side effects via `idempotency_key` | Adapter contract §7/§8 | L0 read-only: N/A (no tools invoked); classification table exists | Inject tool error; verify idempotency echo |
| S2 | Approval timeout | L2/L3 without approval → `needs_approval` + expiry; approval bound to task_id + policy version; no replay | Contract §5 | L0 auto; no approval flow exercised; `needs_approval` status defined in §3 | Exercise approval-request payload + expiry |
| S3 | Context deviation | Unapproved context use → reported in `deviation` field; task aborts | Contract §3/§4 | Compiler `errors/warnings` arrays = 0 (no deviation detected) | Inject unapproved context ref; verify abort |
| S4 | Credential-scope violation | Tool outside `approved_tool_scope` → hard stop | Contract §6 | `credential_ref` = none at Stage 0; no credentials touched | Inject out-of-scope tool with credential; verify stop |
| S5 | Runtime crash mid-task | State recovery, no orphaned mutations, retry/reconciliation | Contract §7/§8 | No runtime; recovery procedure exists in rollback plan §7 | Kill runtime mid-task; verify no orphan writes + task reconciliation |
| S6 | Rollback | Revert to pre-install snapshot; gates pass; audit preserved | Rollback plan §3-§7 | Pre-install baseline captured (this Stage 0); no install → nothing to roll back | Execute rollback plan end-to-end post-spike |

## Result

- 6/6 recovery designs have a defined, documented contract response at the AI-OS level.
- 0/6 exercised as real runtime tests (correctly out of scope for Stage 0).
- **Simulation verdict:** PASS (design completeness) — with explicit note that this is NOT runtime validation.
- Stage 1 must execute S1-S6 against a real reversible spike to convert simulation → validation (pilot design §8, rollback plan §7).

## Honesty constraint

These simulations do not imply Hermes behavior. They verify the **contract and plan documents** are complete and internally consistent, which is the Stage 0 objective. Any Stage 1 result may still fail or deviate — that is the purpose of the spike.
