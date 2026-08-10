# Hermes Local Pilot — Execution Report (LOCAL)

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Authorization:** Owner-approved immediate local install + evaluation.
**Mode:** LOCAL-ONLY. No production/VPS/DNS/Cloudflare, no credentials/secrets, no MCP/API/browser automation, no destructive change to GOFFICE, no merge to main.

## 1. Verdict

**LOCAL_PILOT_PARTIAL**

Installs + smoke + rollback: PASS. Real task execution through Hermes: **BLOCKED at the model-provider boundary** (Hermes requires a model API key / network call; credentials and network are forbidden; no offline/mock provider exists). Honest result — this is a genuine capability constraint discovered by the real install, not a stall.

## 2. Installed artifacts

| Item | Value |
|---|---|
| Hermes product | NousResearch/hermes-agent |
| Tag | `v2026.8.3` (annotated; tag object `7de39e700d2c329e15d32eb0b96e2f7cdd9fbdb2`) |
| **Full commit SHA (verified during install)** | **`3c27eb6234bf91b8ceee9e9071591b31e9b148cb`** — `git rev-list -n 1 v2026.8.3` exact match |
| Tag signature | SSH ed25519, `Good "git" signature … ED25519 key SHA256:x9xNOpeJhoEAY2gWhmWHZROC3QF3VjOEbmNo9vQ8y2A` (verified with local allowed-signers file) |
| Installed version | `Hermes Agent v0.20.0 (2026.8.3)`, Python 3.12.10, editable install `-e git+…@3c27eb6…` |
| License | MIT |
| Sandbox path | `F:\projectAi\ai-operating-system\.runtime\hermes-agent` (repo-local, gitignored) — **removed at rollback** |
| Obsidian | v1.13.4 (winget `Obsidian.Obsidian`, exit 0, installer hash verified) |
| **Obsidian vault path** | **`F:\projectAi\ai-operating-system`** (repo root as vault; repo Markdown = source of truth; `.obsidian/` config + `00_Dashboard/VAULT_INDEX.md` links only, no duplication) |

## 3. Test results

| Test | Result | Evidence |
|---|---|---|
| A. Hermes smoke | **PASS** | `--version` → v0.20.0 (exit 0); `--help` → 59 subcommands; `hermes doctor` → passed (warnings only: missing `.env`, SQLite WAL advisory) |
| B. Obsidian vault | **PASS** | winget installed 1.13.4; vault config valid JSON; `VAULT_INDEX.md` links 8 canonical docs; exe launch ran (PID + Electron children) |
| C. Real integration (GOFFICE2026 read-only via adapter → Hermes) | **BLOCKED** | `hermes -z "Say OK"` → `HTTP 400: The supported API model names are deepseek-v4-pro or deepseek-v4-flash, but you passed .` — model provider call required; no API key/network permitted; no offline provider exists |
| D. Context isolation / approval / idempotency / fallback | PARTIAL | Stub-validated 13/13 (Stage 1). Real-runtime D-tests **not runnable** — require model-backed execution |
| E. Baseline comparison | PARTIAL | Offline metrics measured (§4); execution-quality comparison not possible |
| F. Rollback proof | **PASS** | §5 |

## 4. Baseline comparison (Stage-1 stub vs real Hermes, offline-measurable)

| Metric | Stage-1 stub | Real Hermes (offline) | Delta |
|---|---|---|---|
| AI-OS compiled context | 3,702 chars / est. 926 tokens | unchanged (AI-OS side) | — |
| Hermes fixed system prompt | n/a | **11,169 chars / est. ~2,792 tokens** (`hermes prompt-size --json`) | +11,169 chars fixed overhead before any task |
| Scenario pass rate | 13/13 (100%) | 0 executable (all blocked at provider) | n/a |
| Operator effort | 5 steps | install: ~5 steps (clone, verify, venv, pip, smoke) | +install burden |
| Cost | 0 | 0 (no call completed) | 0 |
| Traceability | contract audits (12/13) | contract prep only; runtime audit N/A | n/a |

Measured benefit: **Hermes adds ~11.2 KB fixed system-prompt overhead** before any GOFFICE2026 context is attached — a concrete, quantified integration cost for the pilot to absorb (vs AI-OS compiled 3.7 KB).

## 5. Rollback result

- Removed `F:\projectAi\ai-operating-system\.runtime\hermes-agent` (`Test-Path` → False).
- AI-OS after removal: bootstrap gate **PASS 7/7**; `validate-indexes.ps1` **PASS** → AI-OS does not depend on Hermes.
- Vault after removal: `.obsidian/` config intact, `VAULT_INDEX.md` present, Obsidian 1.13.4 installed → vault remains usable.
- `.runtime/` gitignored (no residue committed). **ROLLBACK: PASS.**

## 6. Measured benefits / limitations

**Benefits:** pin verified cryptographically (SSH-signed tag + SHA); sandbox fully isolated + reversible; quantified offline overhead baseline; AI-OS Control Plane authority untouched (no Hermes writes to canonical knowledge; vault = repo as SoT).

**Limitations (honest):**
1. Hermes **cannot execute any task without a model provider API key** (33 cloud providers; `custom` needs a local server on a port — forbidden). No mock/offline provider.
2. Therefore integration execution, approval enforcement, retry/idempotency, and failure-fallback at the real runtime are **untested** — only contract/stub-level.
3. Task syntax discovery cost (CLI differs from expected `task` subcommand; actual path = `-z`/`chat` + provider config).
4. Obsidian GUI verification was partial (headless; processes ran, no visual confirm).

## 7. Files changed (committed)

- New: `06_Research/pilots/v1.6-hermes/HERMES_INSTALL_EVIDENCE.md` (subagent-recorded)
- New: `06_Research/pilots/v1.6-hermes/OBSIDIAN_INSTALL_EVIDENCE.md` (subagent-recorded)
- New: `06_Research/pilots/v1.6-hermes/LOCAL_PILOT_REPORT.md` (this file)
- New: `00_Dashboard/VAULT_INDEX.md` (vault index links)
- New: `.obsidian/app.json`, `.obsidian/appearance.json`, `.obsidian/core-plugins.json` (vault config, reproducible)
- Modified: `.gitignore` (+`.runtime/`)
- Updates (evidence-backed): `03_Architecture/ROADMAP.md`, `07_Memory/CURRENT_STATE.md`, `07_Memory/SYSTEM_MEMORY.md`, `12_Indexes/knowledge_index.json`

Never committed: `.runtime/` tree, venv, pip caches, hermes logs, node_modules.

## 8. Production recommendation

**NO_GO** (unchanged). No production/VPS/deploy/DNS/Cloudflare action performed or authorized. The model-credential dependency found here is an additional reason production usage is not implied.

## 9. Next gate (owner decision)

- **Gate B install = DONE (local sandbox, now rolled back).** Evidence recorded.
- **Real execution spike:** requires owner decision on model-provider configuration — either (a) approve a scoped API key for a future run (explicitly out of current authorization), or (b) provide a local model endpoint (requires port allowance), or (c) defer real-execution validation.
- Until then: **real-runtime integration remains NOT validated**; stub contract evidence stands (13/13).
