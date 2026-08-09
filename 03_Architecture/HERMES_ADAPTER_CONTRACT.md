# Hermes Adapter Contract

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Status:** Draft v0.1 — implementation-neutral; no runtime code.
**Supersedes:** none (new contract).
**Governed by:** ADR-0013, Blueprint V4 §6/§10/§11/§12/§13/§17.

## 1. Purpose

Define the boundary between the AI-OS Control Plane and the Hermes orchestration runtime so that either side can be changed without breaking governance, knowledge, or audit. This contract is intentionally free of implementation details (language, SDK, transport) until the compatibility spike selects them.

## 2. Governed Task Contract (inputs)

Every unit of work handed to Hermes must carry:

| Field | Requirement |
|---|---|
| `task_id` | Unique, stable identifier; audit/idempotency dedup key |
| `idempotency_key` | Stable key enabling safe retry without duplicate side effects |
| `project_id` / project context | Resolved by AI-OS Project Adapter |
| Governance policy version | ADR/SOP/policy snapshot identifier |
| Mandatory context | Compiled prompt/context package (AI-OS authority) |
| Bootstrap attestation | Evidence the bootstrap gate passed |
| Quality gate attestation | Evidence the prompt quality gate passed |
| Execution level | L0-L4 per v4 §11 (impact-based) |
| Data classification | Per v4 §10; drives logging, masking, retention |
| Approved tool scope | Explicit allow-list; must be consistent with execution level |
| Approved model scope | Policy-selected candidate models |
| Approval evidence | For L3/L4: human approval record bound to `task_id` + context/policy versions |
| `credential_ref` | Task-scoped secret reference (never the secret itself); grant lifecycle per §6 |
| Budget limits | Time/token/cost ceiling; exhaustion aborts the task with evidence (`aborted`) |

## 3. Outputs / execution evidence

Hermes must return, per task:

- Result payload or failure record
- `task_id` echo
- Tool invocation log (what, when, which scope)
- Model/provider used
- Runtime version
- Start/end timestamps
- Validation-relevant metrics (latency, token/cost where available)
- Status: `success` | `failed` | `needs_approval` | `aborted`
- Retryable marker for failed tasks (`retryable` vs `non-retryable` per §7)
- Idempotency state echo for retried `task_id` (existing/duplicate result)

Outputs must not silently overwrite canonical knowledge (see §9).

## 4. Context handoff

- AI-OS compiles and validates context before handoff; Hermes does not re-derive mandatory context.
- Context package is treated as immutable input for the task; any deviation must be reported in outputs and audit (`deviation` field).
- Handoff is one-directional at task start; incremental context updates require a new governed task or explicit approval.

## 5. Approvals

- L0/L1: automatic per policy.
- L2: policy-controlled writes.
- L3 (external mutation/publish/deploy): human approval required by default per policy (v4 §11); L4 (security, secrets, destructive, high-impact): explicit owner approval + audit evidence.
- Approval records are bound to `task_id` + context version + policy version, carry an expiry, and cannot be replayed against another task or a changed context; context change invalidates the approval (re-approval required).
- If a task returns `needs_approval`, the runtime returns an approval-request payload (`task_id`, proposed action, tool scope, impact level) to the AI-OS approval channel; unanswered requests expire per policy.
- Hermes must not escalate its own permissions or bypass approval policy.

## 6. Tool / model constraints

- Hermes may only invoke tools in the approved allow-list for the task.
- Approved tool scope must be consistent with the execution level (an L2 task cannot carry L4-scoped tools).
- `credential_ref` grants are task-scoped: defined issuer, expiry, and revocation; resolved to actual secrets only inside the runtime boundary and never logged; credential scope ⊆ approved tool scope.
- Model selection follows AI-OS routing policy; Hermes executes the selected route.
- No new credentials for Hermes beyond the task-scoped grant; no secrets in prompts, logs, or audit records (v4 §12).
- Network/zero-trust posture: minimize directly exposed runtime services.

## 7. Failure semantics

- Fail closed for mutations when state is uncertain.
- Stop unsafe execution immediately on policy or security violation (v4 §17).
- On uncertain mutation outcome, hold for human reconciliation before any retry or continuation.
- Record failure evidence (task_id, phase, error category).
- Distinguish: retryable (transient) vs non-retryable (policy/validation) failures.
- Non-retryable failures return to human review or alternative-runtime continuation per policy.
- Failure of Hermes must not lose AI-OS knowledge or project state (v4 §17).

## 8. Idempotency / retry

- Each task must be safely retryable: repeated execution of the same `task_id` / `idempotency_key` must not duplicate side effects.
- Mutations must carry idempotency keys; on uncertain outcome, verify before retry, never blindly re-execute.
- Retry policy (max attempts, backoff, escalation) is defined per execution level; L3/L4 retries require re-approval if context changed.
- A retry-policy annex (max attempts, backoff, escalation per L0-L4) is required before the compatibility spike is drafted.

## 9. Memory / knowledge boundary

- Hermes runtime state is execution convenience only.
- Canonical knowledge, project memory, ADRs, and governance artifacts live in AI-OS versioned repositories (Git SoT, ADR-0002/0003).
- Promotion of validated outcomes into knowledge requires AI-OS validation + review; Hermes cannot write canonical knowledge directly.
- Runtime memory must not silently replace or shadow canonical records.

## 10. Audit fields

Each task contributes to the audit record:

- `task_id`, `actor` (human/agent), `project_id`
- Context package version
- Governance policy version
- Data classification
- Runtime (Hermes) version
- Model/provider
- Tools used
- Approval records
- Deviations, retries, and escalation events
- `credential_ref` usage (non-secret reference only)
- Result + validation
- Knowledge updates (if any, with promotion evidence)

Audit records are keyed by `task_id`; Hermes execution evidence and AI-OS audit are reconciled and deduplicated on `task_id` (single audit source of truth).

## 11. Non-goals / STOP

- No Hermes installation in this phase.
- No secrets changes, production deployment, DNS, or VPS mutation.
- No automatic promotion of Hermes to default runtime without pilot evidence (ADR-0013 §4).
- No second workflow engine built inside AI-OS (v4 §5).

## 12. Open items for compatibility spike

- Transport/serialization choice for the contract.
- Failure taxonomy mapping to Hermes-native error semantics.
- Audit export format and observability mapping (v4 §13).
- Rollback plan (ROADMAP v1.6 exit criteria) to be documented before any install.
