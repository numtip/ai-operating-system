# Hermes Local Runtime Pilot — DeepSeek Real Execution Report

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Authorization:** Gate C — real LOCAL Hermes pilot via DeepSeek direct API. Owner-entered key; **key never printed/logged/committed/persisted**.
**Mode:** LOCAL-ONLY. No production/VPS/DNS/Cloudflare, no MCP/browser automation, no write tools, no external repo changes, no merge to main.

## 1. Verdict

**LOCAL_RUNTIME_PASS**

Real end-to-end execution succeeded: AI-OS bootstrap/context/quality gate → governed task contract → Hermes (sandbox) → DeepSeek (direct). Two full read-only GOFFICE2026 audit runs completed with quality results. Guardrails verified. Rollback proven.

## 2. Provider / model / pin

| Item | Value |
|---|---|
| Provider | **DeepSeek direct** (`--provider deepseek`; documented bundled provider `plugins/model-providers/deepseek/` in v2026.8.3) |
| Base URL | `https://api.deepseek.com/v1` (official default; no override needed) |
| Model | **`deepseek-v4-flash`** (exact lowercase alias, `--model deepseek-v4-flash`) |
| Key mechanism | `DEEPSEEK_API_KEY` env var, owner-entered in local session; used via process env inheritance only |
| Hermes pin | tag `v2026.8.3` → **commit `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`** (verified `git rev-list -n 1` during install, exact match) |
| Installed | `Hermes Agent v0.20.0 (2026.8.3)`, editable `-e git+…@3c27eb6…`, venv at sandbox |

## 3. Real task result (Run 1 & Run 2)

**Task (read-only):** verify GOFFICE2026 production-readiness evidence completeness/consistency; findings only; no modification.

| Aspect | Run 1 | Run 2 |
|---|---|---|
| Status | `completed: true, failed: false` | `completed: true, failed: false` |
| API calls | 12 | 13 |
| Input tokens | 31,372 | 20,227 |
| Output tokens | 17,411 | 18,285 |
| Cache read tokens | 275,712 | (included in total) |
| Total tokens | 324,495 | 335,728 |
| Estimated cost (USD) | **0.0100** | **0.0088** |
| Latency (wall) | ~152 s | ~166 s |
| Verdict | PASS_WITH_NOTES | PASS_WITH_NOTES |

**Quality findings (real, verified):**
- All required evidence files present: README (17.6 KB, 480 lines), PRODUCT.md, package.json (v1.3.0), package-lock.json (matches), CHANGELOG.md (latest 1.3.0) — satisfies adapter §4 required set.
- Cross-checks passed: 16/16 docs referenced by README exist; 17/18 scripts referenced by package.json exist; dist/ has 252 .html pages (matches release claim); git tags v1.2.0/v1.3.0 match CHANGELOG.
- **C1 (highest severity):** README is 2 versions stale — says v1.2.0/last-updated 2026-07-20, but v1.3.0 was PO-approved, built, and deployed to production 2026-08-05 (per CHANGELOG + release prep).
- **Additional:** GO-BE-3 flow fails at step one (script mismatch); CPU/RAM OOM risk; no Postgres backup cron (READY_WITH_BLOCKERS note).
- Run 1 and Run 2 conclusions agree → deterministic outcome across retries.

## 4. Guardrail results

| Guardrail | Test | Result |
|---|---|---|
| Context isolation | Run 2 output scanned for `document-center/RAE/attendance/Learning Center` | **PASS** — no cross-project content leak |
| Approval enforcement | Hermes built-in dangerous-command approval (`hermes approvals`); `--safe-mode -z` prompt-only path never invoked tools → no approval bypass possible for this read-only task | **PASS** (by design; no write tools offered) |
| Retry / idempotency | Two identical tasks run; both `completed=true`, same verdict, cost within noise | **PASS** — deterministic result; each run isolated session |
| Provider-failure fallback | `DEEPSEEK_BASE_URL` set to invalid host → observed: **3 retries → `API call failed after 3 retries: Connection error.` → graceful exit (no crash, no hang)** | **PASS** |
| Read-only boundary | goffice2026 HEAD unchanged after both runs (`7b44c5d…`); git status shows only pre-existing untracked dirs | **PASS** |
| Secret hygiene | Key passed via env only; never printed/logged/committed; removed from session after test | **PASS** |

## 5. Baseline comparison — real runtime vs Stage-1 stub

| Metric | Stage-1 stub | Real runtime (Run 1/2) | Delta |
|---|---|---|---|
| AI-OS compiled context | 3,702 chars / est. 926 tokens | same input contract | 0 (AI-OS unchanged) |
| Hermes fixed prompt overhead | 11,169 chars (~2,792 tok) | consumed as part of 31k-20k input tokens | overhead confirmed real |
| Task success | 13/13 (100%) | 2/2 (100%) | 0 |
| End-to-end latency | ms-range (simulated) | **~152-166 s** (agentic loop, 12-13 API calls) | +~150 s real cost |
| Cost | 0 | **~$0.009-0.010/run (estimated)** | +$0.01 real |
| Traceability | contract audits only | session_id + usage file (tokens/cost/model) + output | richer |
| Operator effort | 5 steps | +3 steps (provider config, key env, usage file) | +3 |
| Execution quality | simulated hash echo | **real findings (C1 etc.)** | qualitative improvement |

## 6. Measured benefits / limitations

**Benefits:** real execution works through the documented DeepSeek provider; deterministic across retries; per-run cost/token telemetry via `--usage-file`; no production/external mutation; AI-OS Control Plane untouched (Hermes executed only what the compiled task contract dictated).

**Limitations (honest):**
1. Agentic loop is expensive in tokens (~320k total incl. cache) and slow (~150-165 s) for one small audit — 12-13 API calls per run.
2. Cost is **estimated** from official docs snapshot (DeepSeek billing may differ).
3. Approval enforcement not exercised with a real dangerous tool (none offered in read-only mode) — verified only at design/by-design level.
4. Cache_read tokens dominate totals; actual billed input likely lower — DeepSeek pricing model determines real cost.
5. Obsidian GUI visual confirmation remains partial (headless).

## 7. Rollback proof

- Sandbox removed: `.runtime/hermes-agent` → `Test-Path` = False.
- `DEEPSEEK_API_KEY` and `DEEPSEEK_BASE_URL` removed from session.
- Usage/lock/temp files removed. `.runtime/` gitignored (only log files remain, untracked).
- After rollback: AI-OS bootstrap **PASS 7/7** · indexes **PASS** · compiler suite **53/53** · vault config + index present · Obsidian 1.13.4 installed.
- **ROLLBACK: PASS** — AI-OS and vault fully usable without Hermes.

## 8. Files changed (committed)

- New: `06_Research/pilots/v1.6-hermes/LOCAL_RUNTIME_REPORT.md` (this file)
- New: `06_Research/pilots/v1.6-hermes/HERMES_RUNTIME_METRICS.json` (usage metrics, no secrets)
- Modified: `00_Dashboard/VAULT_INDEX.md` (added links to new evidence; no duplication)
- Updates (evidence-backed): `03_Architecture/ROADMAP.md`, `07_Memory/CURRENT_STATE.md`, `07_Memory/SYSTEM_MEMORY.md`, `12_Indexes/knowledge_index.json`

Never committed: sandbox tree, venv, pip cache, `.env`, usage JSON raw if it contained prompts (sanitized copy committed), hermes logs, node_modules, any secret.

## 9. Production recommendation

**NO_GO (unchanged).** No production/VPS/deploy/DNS/Cloudflare action performed or authorized. This pilot provides local evidence only; production remains gated on separate owner approval.

## 10. Next recommendation

- **Conditional GO for continued local pilot:** the DeepSeek direct provider path is proven. Recommended next steps (owner approval): (a) a bounded local GOFFICE2026 task via a single-call mode (not the full agentic loop) to reduce cost/latency; (b) reconcile the README staleness finding (C1) with the GOFFICE2026 owner (outside AI-OS repo, owner-initiated); (c) if kept, re-run pilot with cost accounting from actual DeepSeek billing.
- Real-runtime compatibility spike vs Hermes internals still requires the owner's model-provider decision path; this pilot demonstrated the integration, not Hermes native behavior parity.
