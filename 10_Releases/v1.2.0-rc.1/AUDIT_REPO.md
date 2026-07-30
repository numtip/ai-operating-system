# Repository Audit — AI-OS v1.2.0-rc.1

**Date:** 2026-07-30  
**Scope:** Audit only (targeted scans; no redesign, no goffice2026 external edits)  
**Repo root:** `F:\projectAi\ai-operating-system`  
**Overall:** **FAIL**

---

## Summary

| Area | Verdict |
|------|---------|
| 1. Duplicate files | **PASS** |
| 2. Obsolete documents | **FAIL** |
| 3. Canonical references | **PASS** |
| 4. Folder consistency | **PASS** |
| 5. Naming convention | **WARN** |

`scripts/validate-structure.ps1` → **RESULT: PASS**

---

## 1. Duplicate files — PASS

- No accidental same-basename collisions outside expected patterns.
- Intentional shared basenames only: `README.md` (14 module READMEs), `SPEC.md` (bootstrap-runtime + project-adapter), `.gitkeep` (empty vault slots).
- No same-content SHA-256 duplicates among non-README/SPEC/.gitkeep files.
- Templates vs instances not flagged (e.g. `ADR-TEMPLATE.md` vs `ADR-NNNN-*.md`).

---

## 2. Obsolete documents — FAIL

Entry and pilot docs disagree with living v1.2 state.

- **`README.md`** still says **Track: v1.1 — Context Engine Foundation** while `ROADMAP.md`, `SYSTEM_MEMORY.md`, and `CURRENT_STATE.md` describe **v1.2** complete/active.
- **`00_Dashboard/HOME.md`** still **Phase 1 — Obsidian + Git + Knowledge** / **Bootstrap / foundation** (entry dashboard lag).
- **`06_Research/pilots/goffice2026/FINDINGS.md`** and **`VALIDATION_REPORT.md`** still assert High/broken issues that are **already remediated**:
  - `project_index.json` empty / missing goffice2026 → **now has 1 entry** (`project-goffice2026`)
  - `scripts/simulate-bootstrap.ps1` missing → **file present**
  - SYSTEM_MEMORY still v1.1 → **now labels v1.2**
- **`CURRENT_STATE.md`** itself is **not** stuck on “await v1.1”: it correctly states v1.2 complete locally (await commit/push). Open items (approve commits / proposed tag) are process-open, not doc-obsolete.
- **Tag label drift:** living docs propose **`v1.2.0-alpha.1`** (`CHANGELOG.md`, `CURRENT_STATE.md`); this RC audit path is **`v1.2.0-rc.1`** — naming not aligned.

“Phase 1” language in ADRs / prompt-compiler constraints is historical/constraint wording and is **not** scored as obsolete.

---

## 3. Canonical references — PASS

- Root README canonical table targets all resolve: manifesto, HOME, AGENT_BOOTSTRAP, CONTEXT_ENGINE, prompt-compiler/, indexes, ROADMAP, OPERATING_RULES, CURRENT_STATE, ADR/, CHANGELOG, QUICKSTART.
- Entry-doc markdown link scan (`README`, HOME, QUICKSTART, CURRENT_STATE, SESSION_INDEX, SYSTEM_MEMORY) → **no broken relative links**.
- Spot-check of SOP/architecture/pilot/project READMEs → **no broken relative links**.
- **`04_ADR/README.md`** indexes ADR-0001…ADR-0010 + template; all linked files exist; all numbered ADR files appear in the index.
- **`12_Indexes/adr_index.json`**: 10 entries ↔ 10 numbered ADR files.

---

## 4. Folder consistency — PASS

README vault tree expects `00`–`12`, `Archive/`, `scripts/`. Top-level directories present:

`00_Dashboard`, `01_Projects`, `02_Knowledge`, `03_Architecture`, `04_ADR`, `05_Meetings`, `06_Research`, `07_Memory`, `08_Skills`, `09_SOP`, `10_Releases`, `11_Templates`, `12_Indexes`, `Archive`, `scripts`

Root files: `README.md`, `CHANGELOG.md`, `AI_OS_MANIFESTO.md`, `.gitignore`. Structure validator PASS.

---

## 5. Naming convention — WARN

| Rule | Result |
|------|--------|
| `ADR-NNNN-slug.md` | **PASS** — ADR-0001…0010 match `ADR-\d{4}-[a-z0-9-]+\.md`; `ADR-TEMPLATE.md` exempt |
| Session `YYYY-MM-DD-topic.md` | **WARN** — date prefix OK; 2/3 sessions use **dots** in topic (`v1.1`, `v1.2`), which fail a strict `[a-z0-9-]+` slug |

Sessions:

- OK: `2026-07-30-bootstrap-knowledge-memory.md`
- WARN: `2026-07-30-v1.1-context-engine-foundation.md`
- WARN: `2026-07-30-v1.2-goffice2026-pilot.md`

`SESSION_INDEX.md` documents `YYYY-MM-DD-topic.md` without forbidding version dots; treat as convention tightness, not breakage.

---

## Top findings (priority)

1. **FAIL** — Root `README.md` track still **v1.1** while system is on **v1.2**.
2. **FAIL** — `00_Dashboard/HOME.md` still Phase 1 / bootstrap foundation.
3. **FAIL** — Pilot `FINDINGS.md` / `VALIDATION_REPORT.md` unretracted after index + simulate-bootstrap + memory remediations.
4. **WARN** — Release identity mismatch: **`v1.2.0-rc.1`** (this folder) vs proposed tag **`v1.2.0-alpha.1`**.
5. **WARN** — Session filenames with `v1.x` dots vs strict slug `YYYY-MM-DD-[a-z0-9-]+`.

---

## Method (targeted; no full-repo dump)

- Top-level dir listing vs README vault tree
- Basename grouping + content-hash scan for accidental duplicates
- README + entry-doc relative link resolution
- ADR README ↔ files ↔ `adr_index.json`
- Grep for version/phase drift and stale pilot claims
- Session/ADR filename regex
- `scripts/validate-structure.ps1`

---

## Out of scope

- No commits / push
- No architecture redesign or feature work
- External `F:\projectAi\goffice2026` not modified
