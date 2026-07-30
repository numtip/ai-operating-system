# Validation Report — goffice2026 pilot

**Date:** 2026-07-30  
**AI-OS track:** v1.2 (metrics / bootstrap-runtime specs); system memory still labels v1.1  
**External tip:** `65360ea`  
**Token method:** Method A — `tokens_est = ceil(chars / 4)`  
**Scope:** Recommendations only. External tree not modified.

---

## 1. Bootstrap completeness

| Check | Result |
|-------|--------|
| Session SOP (`09_SOP/AGENT_BOOTSTRAP.md` + checklist + manifest) | Present; ordered memory → state → git → context |
| Context Engine + PROJECT_CONTEXT_LOADING | Present; minimal-required-read policy clear |
| Project adapter (`01_Projects/goffice2026/ADAPTER.md`) | **Present** (Subagent A surface delivered) |
| Project entry README | Present |
| Project memory (`07_Memory/projects/goffice2026.md`) | Present but thin (pointers only) |
| `12_Indexes/project_index.json` entry for goffice2026 | **Missing** (entries empty; stale note) |
| Bootstrap runtime (`03_Architecture/bootstrap-runtime/`) | Spec present; `scripts/simulate-bootstrap.ps1` **missing** |
| `09_SOP/PROJECT_BOOTSTRAP.md` / BOOTSTRAP_CONTEXT_PACKAGE | Present |

**Verdict:** Core session bootstrap is complete; **project discovery via index is incomplete**, so runtime algorithm step 1 fails soft/hard until index is regenerated.

---

## 2. Missing memory

| Gap | Why it matters |
|-----|----------------|
| No durable project focus / open blockers in memory | Tip notes M365 Canvas app + Flow not persisted; agents re-discover from CHANGELOG |
| No “do not touch” / write-bounds for external path | Risk of agents editing goffice2026 despite pilot ADR |
| SYSTEM_MEMORY version still “v1.1” | Conflicts with v1.2 metrics/bootstrap docs |
| Index does not point at adapter/memory | Bootstrap-runtime cannot resolve `goffice2026` by name |

---

## 3. Duplicate knowledge risks

| Risk | Observation |
|------|-------------|
| Adapter body duplication | Low — adapter is pointers-only (good) |
| Memory duplication | Low — memory does not paste PRODUCT/DESIGN |
| Adapter `required: true` on large docs | **High** — `docs/GOFFICE2026_NEW_PROJECT_MASTER_REFERENCE.md` ≈ 90 443 chars (~22 611 tok) marked required |
| README vs PRODUCT/DESIGN overlap | Medium in **external** repo (expected); AI-OS must not mirror |
| Multiple blueprints under `docs/` | External corpus has overlapping architecture docs; adapter should rank, not ingest all |

---

## 4. Broken / stale references

| Reference | Status |
|-----------|--------|
| Links inside AGENT_BOOTSTRAP / CONTEXT_ENGINE / PROJECT_CONTEXT_LOADING / project-adapter README | OK (spot-checked) |
| Adapter canonical paths on disk (README, PRODUCT, DESIGN, CHANGELOG, constitution, master_reference) | OK at tip |
| `12_Indexes/project_index.json` note “No project folders…” | **Stale** — `01_Projects/goffice2026/` exists |
| `bootstrap-runtime/README.md` → `scripts/simulate-bootstrap.ps1` | **Broken** (file absent) |
| Memory relative link `../../../goffice2026/README.md` | Resolves when vault sits under `F:\projectAi\` (environment-coupled) |

---

## 5. Unnecessary reads

| Pattern | Cost (chars/4) | Recommendation |
|---------|----------------|----------------|
| Ideal adapter path (9 files) | **~2 841 tok** | Prefer |
| Follow all adapter `required: true` docs | **~32 918 tok** | Demote master_reference / README to on-demand |
| Naive root `*.md` + `docs/**/*.{md,MD}` | **171 files / ~263 144 tok** | Never for bootstrap |
| Shallow docs set (root + ops/sharepoint one-level sample) | **~38 files / ~89 197 tok** | Still too large for session start |

Primary waste driver if agents “load all required canonical docs”: **master_reference (~22.6k tok)**.

---

## Estimated bootstrap file set (ordered)

Ideal path for a goffice2026 session (stop when enough):

1. `07_Memory/SYSTEM_MEMORY.md` — ~316 tok  
2. `07_Memory/CURRENT_STATE.md` — ~305 tok  
3. `09_SOP/AGENT_BOOTSTRAP.md` — ~326 tok  
4. `03_Architecture/PROJECT_CONTEXT_LOADING.md` — ~394 tok  
5. `12_Indexes/project_index.json` — ~52 tok *(must list goffice2026)*  
6. `01_Projects/goffice2026/ADAPTER.md` — ~480 tok  
7. `07_Memory/projects/goffice2026.md` — ~91 tok  
8. `F:\projectAi\goffice2026\PRODUCT.md` — ~488 tok *(identity / users)*  
9. `F:\projectAi\goffice2026\package.json` — ~389 tok *(name/version/scripts)*  

**Subtotal ideal:** 9 files · **~2 841 tokens** (chars/4)

**Task-conditional (do not load by default):**

10. `CHANGELOG.md` — recent state (~1 194 tok)  
11. `docs/00-GREENOFFICE_PROJECT_CONSTITUTION.MD` — constraints (~1 383 tok)  
12. `DESIGN.md` — UI work only (~1 493 tok)  
13. Targeted ops/runbook cited by task — not whole `docs/`  

**Rough ceiling if orientation needs constitution + changelog:** ~2 841 + 1 194 + 1 383 ≈ **~5 418 tok** (still ≪ naive).

---

## RECOMMENDATIONS

- Regenerate `12_Indexes/project_index.json` so `goffice2026` → `01_Projects/goffice2026/` (+ tags `external`, `pilot`, `adapter`).
- Keep adapter **link-don’t-copy**; demote `master_reference` (and likely full `README.md`) from `required: true` to `on_demand` / task-gated.
- Enrich `07_Memory/projects/goffice2026.md` with: tip, open M365 blockers, write-bounds (`do_not_modify: F:\projectAi\goffice2026` unless task says otherwise), next focus — still no product paste.
- Add hard rule in bootstrap/extra_steps: never recurse `docs/`, never open `node_modules` / `dist` / `.git`.
- Ship or unlink `scripts/simulate-bootstrap.ps1` (broken ref from bootstrap-runtime README).
- Align SYSTEM_MEMORY / CURRENT_STATE version labels with v1.2 when v1.2 track is active.
- Prefer PRODUCT + package.json for identity; use CHANGELOG only when “what changed” matters; constitution when policy conflicts.
- Treat overlapping external blueprints as **cited by ADR/task**, not bootstrap defaults.
- Optional: add `default_bootstrap_reads` ordered list on adapter (max N paths) separate from full canonical catalog.
- Run formal benchmark series from `BENCHMARK_DRAFT.md` after index regen (same Method A).
- Do not copy goffice docs into `02_Knowledge/` or `01_Projects/` bodies.
- Head Agent should gate any write under goffice2026; this pilot folder remains recommendation-only.
