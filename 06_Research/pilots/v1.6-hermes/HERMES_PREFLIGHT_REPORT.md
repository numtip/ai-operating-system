# Hermes Preflight Report & Proposed Local Sandbox Design

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Status:** PRE-INSTALL DESIGN — nothing installed, no network/dependency/download, no credentials touched.
**Product pin:** `NousResearch/hermes-agent` tag `v2026.8.3` → commit `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` (see ADR-0014).
**This document does not authorize installation.** It defines the prerequisites and acceptance criteria for a later, separately-approved install gate.

## 1. Preflight verdict (summary)

Governance review (subagent 2, 2026-08-09): **GOVERNANCE_READY_WITH_FIXES** — AI-OS Control Plane authority posture is sound (Blueprint §6/§21, adapter contract §9/§10, rollback §4/§5), with required fixes listed below. Combined with the product pin (ADR-0014), preflight outcome: **READY_FOR_LIMITED_LOCAL_INSTALL** (conditional on all §6 prerequisites being satisfied at install time — see §9 verdict framing).

## 2. AI-OS Control Plane authority (preserved)

- Hermes is the **execution runtime only**; AI-OS retains: context selection/compilation, bootstrap gate, prompt quality gate, approval policy (L0-L4), audit source-of-truth, canonical knowledge, ADR history, governance policy (Blueprint V4 §6; adapter contract §9-§10).
- Hermes runtime memory is **ephemeral and disabled** for the pilot; no persistence of compiled context packages; **knowledge promotion disabled** (human + AI-OS gate only).
- Per-task audit export to the AI-OS repo audit location (never sandbox logs as the only record) — closes contract §12 open item.

## 3. Sandbox design (repo-local, pinned, reversible)

```
F:\projectAi\ai-operating-system\
  .gitignore                         # + sandbox dir + venv (committed)
  sandbox/hermes/                    # repo-local, gitignored, disposable
    venv/                            # isolated python env (no system python changes)
    src/hermes-agent/                # git tag v2026.8.3 checkout (SHALLOW, tag-pinned)
    offline-lock/                    # dependency lock w/ hashes (committed)
  scripts/hermes-sandbox.ps1         # install/smoke/rollback driver (committed)
  06_Research/pilots/v1.6-hermes/    # evidence + audit (committed)
```

- **Isolation:** repo-local directory only. No global/system install, no Docker, no service, no scheduler, no ports, no PATH/profile edits, no VPS.
- **Dependency download:** permitted **once** at install (network allowed ONLY for the pinned git tag + locked deps), then **network egress blocked** for sandbox processes; verified offline at smoke/recovery.
- **Write scope:** sandbox processes confined to the gitignored `sandbox/hermes/`; git tool excluded from allow-list; read-only filesystem behavior toward `ai-operating-system` canonical paths and `F:\projectAi\goffice2026`.
- **Replaceability:** delete `sandbox/hermes/` (+ venv) and revert .gitignore → AI-OS returns to pre-pilot state (Rollback Plan §4 manual/alternative continuation unchanged).

## 4. Exact prerequisites (all must hold at install gate)

| # | Prerequisite | Evidence required |
|---|---|---|
| P1 | Owner re-approval at install gate (separate from this design) | Approval record with date |
| P2 | Tag signature verified | `git tag -v v2026.8.3` against pinned SSH key `x9xNOpeJh…` |
| P3 | SHA match | `git rev-parse v2026.8.3` = `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` |
| P4 | Install from git tag only (never PyPI — v0.20.0 not published) | Lock manifest records git ref + SHA |
| P5 | Pre-install snapshot (Rollback Plan §1) + **pip/env-lock delta baseline** (governance fix) | snapshot file committed |
| P6 | Sandbox dir gitignored; AI-OS working tree clean at install start | `git status` clean |
| P7 | AI-OS tests pass (bootstrap, compiler 53/53, Stage 1 stub 13/13, indexes) | run logs |
| P8 | Per-task audit export path defined (contract §10 single source) | audit mapping doc |

## 5. Artifact integrity checks

- Tag object SHA `7de39e700d2c329e15d32eb0b96e2f7cdd9fbdb2` verified via `git tag -v` (SSH ed25519, fingerprint `x9xNOpeJh…`).
- Commit SHA `3c27eb62…` = `git rev-parse v2026.8.3^{commit}`; commit itself unsigned → pin via signed tag + SHA.
- Dependency lock with hashes (e.g. `pip freeze --hash` / uv lock) committed; any drift → STOP + rollback (Rollback Plan §6 extension).
- PyPI mismatch note recorded: latest PyPI `0.19.0` ≠ pinned `v0.20.0/v2026.8.3`.

## 6. Prohibited network/tool settings

- No network targets after the one-time dependency download; no MCP/API/browser access; no credentials/secrets; no ports/services/scheduler; no git writes anywhere; no `pip install` of unpinned packages; no system package manager; no Docker.
- Sandbox processes: block egress (firewall scope / process isolation) and verify offline at smoke + recovery.

## 7. Created-file allowlist (install gate)

Commit: ADR-0014, `HERMES_PREFLIGHT_REPORT.md`, `scripts/hermes-sandbox.ps1`, `.gitignore` entry, dependency lock (`offline-lock/`), pre-install snapshot, audit/evidence docs.
Never commit: vendored binaries, `node_modules`, `sandbox/hermes/` tree, `venv/`, `__pycache__`, `*.egg-info`, logs.

## 8. Rollback procedure + cleanup dry-run

Per `HERMES_ROLLBACK_PLAN.md` §3-§7, extended (governance fixes):
1. Stop processes; disable auto-start (none should exist — manual-run only).
2. **Pip-specific:** remove pinned tree + transitive deps; clear caches; verify pip/env-lock delta equals §1 baseline (fix C-rollback-3).
3. Remove/rename `sandbox/hermes/` to `backup/<ts>/` (never blind delete).
4. Restore environment (no PATH/profile edits by design → nothing to undo; verify residue = none).
5. Verify: `git status` clean for governed repos; gates pass; **sandbox dir absent**; **no env residue**; audit records preserved (fix C-rollback-7).
6. Cleanup dry-run: executed at install gate before any real change — prove the remove/restore sequence works on an empty sandbox (evidence `sandbox-cleanup-dryrun`).

## 9. Acceptance criteria (install gate)

- All P1-P8 hold.
- Smoke only: `./hermes --version` / `--help` / built-in self-test — **no task execution**, no network, no model API.
- Rollback dry-run passes; offline verified.
- Audit record written.
- **Verdict at that point:** if all pass → `READY_FOR_LIMITED_LOCAL_INSTALL` and the later install executes the same checks; any failure → STOP + rollback (BLOCKED).

## 10. First future runtime pilot scope (LIMITED)

- **GOFFICE2026 only**, **read-only** (L0/L1), via the governed task contract (Stage 0/1 baselines).
- No L2-L4; no writes to goffice2026 or AI-OS canonical paths; no model provider changes; metrics vs Stage 0 baseline.
- document-center/RAE/attendance excluded until adapters reconciled (LOCAL_INTEGRATION_VALIDATION_REPORT R2-R4).

## 11. Consistency

Aligned with: Blueprint V4 §6/§11/§12/§17/§21, ADR-0013, ADR-0014, HERMES_ADAPTER_CONTRACT §2/§5/§9/§10, HERMES_ROLLBACK_PLAN §1-§7, LOCAL_INTEGRATION_VALIDATION_REPORT. No production/DNS/VPS/cloud/deploy mutation authorized.
