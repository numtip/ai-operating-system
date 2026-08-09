# Local Cross-Project Integration Readiness Validation Report

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Mode:** LOCAL-ONLY. No Hermes/Obsidian install. No production/VPS/cloud/credentials/API/MCP/deploy/external mutation.
**External repos:** inspected read-only; none modified.

## 1. Per-project status

| Project | Specified path | Actual | Status | Evidence |
|---|---|---|---|---|
| GOFFICE2026 | `F:\projectAi\goffice2026` | EXISTS (canonical per adapter) | **PASS** | npm test 18/18 exit 0 (12.1s); clean tracked tree; HEAD `7b44c5d` = adapter tip |
| Document Center | `G:\ProjectAI\document-center` | G: path ABSENT; canonical repo at `F:\projectAi\document-center` (frozen READ-MOSTLY) | **PARTIAL** | validate:all PASS (9.2s); adapter metadata stale (in_vault vs external repo; no local_path) |
| Attendance Report Generator | `G:\ProjectAI\attendance-report-generator` | NOT FOUND anywhere | **NOT_AVAILABLE** | path absent; no adapter; compile → missing_project |
| RAE Next.js | `G:\ProjectAI\rae-nextjs` | EXISTS (multi-project repo; app in `rae-landing/`) | **PARTIAL** | git CLEAN @ `9f97bce`; runnable (node_modules/.next present); no test script run (lint/build would write); NO AI-OS adapter |
| Learning Center | — | NOT FOUND as local repo | **NOT_AVAILABLE** | no repo path evidence; not guessed |

## 2. Test matrix

| Check | Target | Command | Result | Duration |
|---|---|---|---|---|
| Unit tests | goffice2026 | `npm test` | PASS (18/18, exit 0) | 12.1 s |
| Validation | document-center | `npm run validate:all` | PASS (exit 0) | 9.2 s |
| Build/lint | RAE | `npm run lint`/`build` | NOT RUN (would write `.eslintrc`/`.next`; read-only mandate) | — |
| Bootstrap gate | AI-OS | `check-bootstrap.ps1 -ProjectName goffice2026` | PASS 7/7 | — |
| Index validation | AI-OS | `validate-indexes.ps1` | PASS | — |
| Stage 1 stub regression | AI-OS | `stub/run-stage1.ps1` | PASS 13/13 | — |
| Compile (read-only contract) | goffice2026 | `compile-prompt.ps1` | ok, 8 files | 575 ms baseline |
| Compile (read-only contract) | document-center | `compile-prompt.ps1` | ok, 6 files (no external:doc refs) | — |
| Compile (read-only contract) | RAE / attendance | `compile-prompt.ps1` | error `missing_project` (no adapter) | — |

## 3. AI-OS checks

- **Bootstrap/context/quality gate/index:** all PASS (bootstrap 7/7; indexes RESULT:PASS; compile quality gate 0 errors).
- **Stage 1 stub regression:** 13/13 scenarios PASS (unchanged from Stage 1).
- **Cross-project context isolation:** compile of goffice2026 → 8 files, no RAE/learning/attendance refs (leak=False); compile of document-center → 6 files, no goffice/learning/attendance refs (leak=False). Deterministic hash stable (`08a8e59e…` for this goal).
- **Secret leakage:** grep for API keys/tokens/private keys across `06_Research/pilots/v1.6-hermes/` → none.

## 4. Per-project adapter suitability

| Project | Identity/context | Approval levels | Audit evidence | Read-only boundary | Retry/idempotency | Rollback docs |
|---|---|---|---|---|---|---|
| goffice2026 | PASS (adapter v1.0, local_path verified) | NOT addressed in adapter | NOT addressed | PASS (pointers only, no copy-out) | Contract-level (stub) | `HERMES_ROLLBACK_PLAN.md` |
| document-center | PARTIAL (in_vault label stale vs external frozen repo; no local_path) | NOT addressed | NOT addressed | PARTIAL (no copy-out instructions; not a git repo in vault) | Contract-level | via AI-OS plan |
| RAE | NO ADAPTER (identity not wired) | n/a | n/a | n/a | n/a | n/a |
| attendance | NOT_AVAILABLE | n/a | n/a | n/a | n/a | n/a |

## 5. Readiness score for Hermes local sandbox

**Score: 2.5 / 5** — CONDITIONAL.

- Governance contract surface (AI-OS side): validated via Stage 1 stub (13/13) — strong.
- Real runtime path: only 1 of 5 projects fully wired (goffice2026).
- Adapter metadata drift (document-center) and missing adapters (RAE, attendance) limit the sandbox's usable surface.

## 6. Recommendation

### Local (Hermes sandbox): **CONDITIONAL_GO**
Allowed only if:
1. Owner pins the Hermes product/version/source (see `HERMES_INSTALL_PREFLIGHT.md` — previously STOPPED as ambiguous).
2. Sandbox scope limited to **goffice2026 only** (the one fully-wired project) for the first real spike.
3. document-center adapter reconciled (in_vault vs external) before inclusion.
4. Existing rules honored: repo-local dir, no global/system/Docker/service/ports/PATH, smoke-only, rollback dry-run, docs+lock+scripts committed only.

### Production: **NO_GO** (must remain until owner later approves)
- RAE production sync already blocked (no SSH private key on host).
- No production mutation authorized by this report; staging evidence only.

## 7. Remediation plan (precise, owner-owned)

| # | Item | Owner | Priority |
|---|---|---|---|
| R1 | Pin Hermes product + version + source URL + checksum in an ADR appendix | Owner | HIGH (blocks install) |
| R2 | Reconcile document-center adapter: add `local_path=F:\projectAi\document-center` + external fields, or formalize vault copy as SoT | AI-OS maintainer | HIGH |
| R3 | Create RAE adapter (identity, canonical docs, read-only boundary) before sandbox inclusion | AI-OS maintainer | MEDIUM |
| R4 | Create attendance-report-generator adapter + confirm repo location | Owner/AI-OS | MEDIUM |
| R5 | Add approval/audit/rollback sections to per-project adapters (align with `HERMES_ADAPTER_CONTRACT.md` §5/§10) | AI-OS maintainer | MEDIUM |
| R6 | Re-run this validation after R2/R3 to raise readiness score | AI-OS | After R2-R3 |

## 8. Explicit limitations

- Stub evidence only for contract behavior; no real runtime validation.
- RAE lint/build not executed (read-only mandate); runnable status inferred from node_modules/.next presence.
- document-center inspected at `F:\projectAi\document-center` (specified G: path absent) — canonical location should be confirmed by owner.
- No production safety claimed.
