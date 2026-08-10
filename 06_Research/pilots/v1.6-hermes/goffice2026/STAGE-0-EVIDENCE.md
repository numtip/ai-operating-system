# GOFFICE2026 Pilot — Stage 0 Evidence

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Authorization:** Stage 0 only — read-only. No Hermes, no install, no external repo mutation, no production action.
**Canonical repo note:** Brief specifies `G:\ProjectAI\goffice2026` — path does not exist (drive G: contains `deer-flow`, `rae-nextjs`, `__OLD__rae-landing` only). Evidence obtained from the adapter-declared local path `F:\projectAi\goffice2026` (per `01_Projects/goffice2026/ADAPTER.md`, `local_path`), which exists with HEAD `7b44c5d`. **Resolution 2026-08-09:** `F:\projectAi\goffice2026` established as canonical (ADAPTER.md §3.1); `G:\ProjectAI\goffice2026` recorded as non-canonical with evidence.

## 1. Read-only evidence sources inspected

| Source | Status | Notes |
|---|---|---|
| `F:\projectAi\goffice2026` repo | EXISTS | HEAD `7b44c5d`; untracked `.browser-profile/`, `.vscode/` (not touched) |
| `PRODUCT.md` | read | Static-first bilingual Green Office platform; evidence-first |
| `CHANGELOG.md` | read | v1.3.0 prod prep 2026-08-05; 252 pages; Node 20.19.5 |
| `package.json` | listed | identity present (adapter canonical) |
| Adapter `01_Projects/goffice2026/ADAPTER.md` | read | project_id goffice2026; external; tip 65360ea (stale vs actual HEAD 7b44c5d) |
| Memory `07_Memory/projects/goffice2026.md` | exists | loaded per bootstrap |

No writes performed to `F:\projectAi\goffice2026` or any external/service/credential.

## 2. Stage 0 objective 1 — governed task contract instance (read-only task)

Instantiated per `HERMES_ADAPTER_CONTRACT.md` §2 (all required fields):

| Field | Value |
|---|---|
| `task_id` | `goffice2026-stage0-readonly-audit-2026-08-09-001` |
| `idempotency_key` | `goffice2026-s0-001` |
| `project_id` | `goffice2026` (adapter v1.0, external) |
| Governance policy version | ADR-0013 (2026-08-09) + Blueprint V4 (accepted 2026-08-09) |
| Mandatory context | 8 files selected by compiler (see §4) |
| Bootstrap attestation | PASS 7/7 (`check-bootstrap.ps1 -ProjectName goffice2026`) |
| Quality gate attestation | PASS (0 errors, 0 warnings — compiler quality gate) |
| Execution level | L0 (read project context/indexes) — automatic |
| Data classification | Public/internal (no secrets, no PII beyond public site content) |
| Approved tool scope | Read-only: adapter, indexes, memory, canonical docs (`PRODUCT.md`, `README.md`, `package.json`, `CHANGELOG.md`) |
| Approved model scope | `deepseek-v4-flash` profile (compile-time only; no model call) |
| Approval evidence | Not required (L0 automatic) |
| `credential_ref` | None — no credentials accessed |
| Budget limits | N/A at Stage 0 (no runtime); compile budget: 6-file optimizer budget noted in §4 |

Approval-level check (Blueprint V4 §11): Stage 0 executes only **L0**; **L1** (analyze/recommend) exercised in this evidence doc only; **L2-L4** explicitly out of scope. No approval bypass.

## 3. Stage 0 objective 2 — measurable manual-path baselines

Executed real, deterministic, local-only tooling (no Hermes, no LLM, no network):

| Metric | Baseline (Stage 0) | Source |
|---|---|---|
| Context size (compiled prompt) | 3,702 chars / est. 926 tokens | `compile-prompt.ps1` metrics |
| Context files selected | 8 (all required; budget_max_files=6, required_count=8 → 2 over soft budget, 0 rejected) | compiler metrics |
| Index hits | 4 | compiler metrics |
| Task success rate | 1/1 compile (100%) | compiler status ok |
| Compilation latency | 575 ms | compiler metrics |
| Cost | 0 (no model/provider invoked) | — |
| Auditability | 100% for the single governed task (record in this doc) | contract §10 fields mapped in §5 |
| Operator effort | 3 steps: (1) read 5 brief files, (2) run bootstrap gate, (3) run compile simulation | run notes |
| Governance regression | 0 bypasses (bootstrap PASS, quality gate PASS, no forbidden action) | gate logs + this doc |
| Bootstrap gate | 7/7 PASS, verdict PASS, dirty=0 | `check-bootstrap.ps1 -Json` |
| Index validation | PASS (all indexes, incl. ADR-0013 + v1.6 docs) | `validate-indexes.ps1` |

Note: budget_max_files=6 vs required_count=8 is a **known optimizer budget gap** (context budget tuned for smaller projects); must-fix or documented accept before Stage 1 (see §8 blocker).

## 4. Baseline compile evidence (simulation)

- Tool: `scripts/compile-prompt.ps1` v1.4.0 (read_only=true, no OutDir → no file writes)
- Input: project=goffice2026, goal="Read-only audit of GOFFICE2026 production readiness evidence; no modification", profile=deepseek-v4-flash, constraints=[read-only,no push,no production mutation]
- Deterministic hash `ad907c27495ab3b1e8720f286450c1e762166fd8d0542434ac4abe38e6635381`
- Selected context: ADAPTER.md, CURRENT_STATE.md, OPERATING_RULES.md, SYSTEM_MEMORY.md, project_index.json, external docs (package.json, PRODUCT.md, README.md)
- Subagent plan: 1 (`qa-structure`), read-only, write scope none

## 5. Audit fields (adapter contract §10)

| Field | Value |
|---|---|
| task_id | `goffice2026-stage0-readonly-audit-2026-08-09-001` |
| actor | AI-OS agent (authorized user session) |
| project_id | goffice2026 |
| Context package version | compiler deterministic hash `ad907c…` |
| Governance policy version | ADR-0013 / Blueprint V4 (2026-08-09) |
| Data classification | Public/internal |
| Runtime (Hermes) | NONE (not installed; not invoked) |
| Model/provider | None (compile-time profile only; no model call) |
| Tools used | check-bootstrap.ps1, compile-prompt.ps1, validate-indexes.ps1, read-only file inspection |
| Approval records | None required (L0) |
| Deviations/retries | 1 deviation: canonical repo path mismatch (G: vs F:) — documented §8 |
| `credential_ref` usage | None |
| Result + validation | PASS (bootstrap 7/7, quality gate 0/0, indexes PASS) |
| Knowledge updates | This evidence doc + Stage 0 results (AI-OS repo only) |

## 6. Stage 0 objective 3 — safe failure-injection simulations (design/paper checks)

Only document-level simulations; **no Hermes, no runtime, no mutation** (see `STAGE-0-FAILURE-SIMULATIONS.md` for detail).

Summary: 6 recovery designs exercised as simulated checks — each verified that the AI-OS-side contract defines the correct response, without claiming real runtime validation.

## 7. Stage 0 objective 4 — exit criteria results

| Pilot exit criterion | Result |
|---|---|
| Stage 0 baselines captured | PASS (see §3) |
| Adapter contract exercised with zero governance bypass | PASS (contract §2/§10 fields mapped; L0 only; no bypass) |
| §5 recovery tests pass in spike | N/A — spike is Stage 1 (install-gated); simulations only |
| Auditability = 100% for pilot tasks | PASS (1/1 governed task fully audited) |
| Metrics report comparing pilot vs baseline | Stage 0 baseline report = this doc; pilot-vs-baseline comparison deferred to Stage 1 |
| Recommendation recorded | Stage 1 entry recommendation in `STAGE-0-RESULTS.md` |

## 8. Findings and blockers

> Status 2026-08-09 (pre-Stage-1 remediation): blockers 1-3 below are **RESOLVED**; see §8.1 resolution record.

1. ~~**HIGH — Canonical repo location mismatch:** Brief names `G:\ProjectAI\goffice2026` (does not exist). Adapter declares `F:\projectAi\goffice2026`. Evidence used F: path. Owner must confirm the true canonical location before Stage 1.~~ → **RESOLVED** — `F:\projectAi\goffice2026` established as canonical (ADAPTER.md §3.1, memory entry updated; G: recorded as non-canonical with evidence).
2. ~~**MED — Adapter tip stale:** `ADAPTER.md` tip_commit `65360ea` ≠ actual HEAD `7b44c5d`. Adapter needs refresh (update-only, not history rewrite) before Stage 1.~~ → **RESOLVED** — tip refreshed to `7b44c5d` with verification date/method (ADAPTER.md §2).
3. ~~**MED — Compiler budget gap:** `budget_max_files=6` < required_count=8 for goffice2026; optimizer allows override but flag is surfaced. Decide: raise budget for pilot or accept documented overshoot before Stage 1.~~ → **RESOLVED** — two-tier budget added: `preferred_max_files=6` / `hard_max_files=8` in `deepseek-v4-flash` profile; required refs admissible up to hard cap; `hard_cap_breached` warning if exceeded (bounded exception, see `prompt-compiler/README.md`).
4. **LOW — Untracked files in canonical repo:** `.browser-profile/`, `.vscode/` at `F:\projectAi\goffice2026` — untouched; confirm they are expected (likely local dev artifacts).

### 8.1 Resolution record (2026-08-09)

- Canonical path decision: `01_Projects/goffice2026/ADAPTER.md` §3.1 + `07_Memory/projects/goffice2026.md`.
- Adapter tip refresh: `01_Projects/goffice2026/ADAPTER.md` §2 (`7b44c5d`, verified 2026-08-09).
- Compiler budget policy: `prompt-compiler/schemas/profile.schema.json`, `prompt-compiler/runtime/Compile-Prompt.ps1`, `prompt-compiler/profiles/deepseek-v4-flash.json`, tests `20.*` added (53/53 PASS).

## 9. No false claims

This document reports **simulation/document checks only** for failure handling and **deterministic local tooling** for baselines. No real Hermes runtime validation occurred; nothing was installed, invoked, or mutated outside the AI-OS repo documentation.
