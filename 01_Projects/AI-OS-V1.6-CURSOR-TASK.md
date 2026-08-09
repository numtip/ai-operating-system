# AI-OS v1.6 — Cursor Execution Brief

**Mode:** token-efficient / evidence-first  
**Branch:** `integration/v1.6-hermes-first`  
**Goal:** Accept Blueprint v4 baseline, remove architecture drift, then prepare Hermes compatibility integration.  
**STOP:** Do NOT install Hermes, change secrets, deploy, change DNS, or mutate production.

## Required read — only these first

1. `03_Architecture/AI_OPERATING_SYSTEM_BLUEPRINT_V4.md`
2. `04_ADR/ADR-0013-integration-first-hermes-runtime.md`
3. `03_Architecture/ROADMAP.md`
4. `03_Architecture/ARCHITECTURE_OVERVIEW.md`
5. `07_Memory/SYSTEM_MEMORY.md`

Read more files only when a concrete conflict/reference requires it.

## Execution

### A. Architecture review
Check the 5 files for contradictions against Blueprint v4 + ADR-0013.

Output a compact matrix:
`file | issue | severity | action`.

Treat Blueprint v4 + ADR-0013 as the current v1.6 architecture direction; preserve historical ADRs.

### B. Reconcile drift
Update only active/current docs that are stale.

Expected likely drift:
- `ARCHITECTURE_OVERVIEW.md` still describes Hermes as deferred.
- `SYSTEM_MEMORY.md` still describes v1.6 as deferred.
- Verify `ROADMAP.md` is aligned with v4.

Do not rewrite historical ADRs to make history look consistent.

### C. Baseline gate
Create:
`03_Architecture/AI_OS_V4_ARCHITECTURE_REVIEW.md`

Minimum contents:
- verdict: PASS / PASS_WITH_NOTES / FAIL
- files reviewed
- contradictions found/fixed
- unresolved risks
- explicit statement whether Blueprint v4 can become v1.6 architecture baseline

If PASS or PASS_WITH_NOTES, change Blueprint v4 status from `Architecture Baseline Candidate` to `Architecture Baseline — Accepted for v1.6` and record acceptance date.

### D. Hermes compatibility spike — design only
Do not install.

Create:
`03_Architecture/HERMES_CAPABILITY_MATRIX.md`

Compare Hermes needs/capabilities with existing AI-OS v1.0-v1.5 capabilities and classify each overlap:
- RETAIN
- ADAPT
- SUPERSEDE
- DEFER

At minimum cover:
context, memory, bootstrap, prompt compilation, quality gate, agents, orchestration, scheduler, tool routing, model routing, approvals, audit, knowledge persistence, n8n boundary, M365/GitHub connectors, observability.

Do not mark SUPERSEDE without concrete evidence.

### E. Adapter contract
Create:
`03_Architecture/HERMES_ADAPTER_CONTRACT.md`

Keep implementation-neutral. Define:
- inputs / governed task contract
- outputs / execution evidence
- context handoff
- approvals
- tool/model constraints
- failure semantics
- idempotency/retry expectation
- memory/knowledge boundary
- audit fields

No implementation code yet.

## Subagents

Use at most 3, only if useful:
1. Architecture consistency review
2. Hermes capability research/matrix
3. Security + adapter-contract review

Give each subagent only the files/section needed. Return conclusions, not raw logs.

## Token rules

- No full-repo reread.
- Search before opening files.
- Read targeted ranges where possible.
- No repeated summaries.
- No pasted command logs unless failure evidence matters.
- Prefer tables/diffs.
- Head Agent integrates outputs; subagents do not duplicate work.

## Validation

Run existing bootstrap/tests relevant to docs/contracts. Do not invent new runtime tests for Hermes before implementation exists.

Before commit:
- `git diff --check`
- verify no secrets
- verify no production/runtime mutation
- verify Blueprint/ADR/Roadmap/Memory agree on v1.6 status

## Git

Work only on `integration/v1.6-hermes-first`.
Commit completed documentation/reconciliation work with concise commits.
Push branch after validation.
Do NOT merge to `main`.

## Final report — max ~40 lines

Report only:
1. VERDICT
2. files changed/created
3. key drift fixed
4. capability matrix summary counts by RETAIN/ADAPT/SUPERSEDE/DEFER
5. adapter contract status
6. validation results
7. commit SHA / remote branch
8. blockers requiring owner approval

Expected end state:
`V4_ARCHITECTURE_BASELINE_ACCEPTED` + `HERMES_INTEGRATION_READY_FOR_COMPATIBILITY_IMPLEMENTATION`

If evidence does not support either state, report the blocker instead; do not force PASS.
