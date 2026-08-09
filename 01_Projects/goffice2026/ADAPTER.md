# Project Adapter: goffice2026

> Spec: `03_Architecture/project-adapter/SPEC.md`  
> Pointers only — canonical docs live in the external repo.

---

## 1. Metadata

| Field | Value |
|-------|-------|
| project_id | goffice2026 |
| display_name | GOffice 2026 |
| status | active |
| owner | numtip |
| adapter_version | 1.0 |
| location_kind | external |

---

## 2. Repository

| Field | Value |
|-------|-------|
| local_path | F:\projectAi\goffice2026 |
| remote_url | https://github.com/numtip/goffice2026 |
| default_branch | master |
| tip_commit | 7b44c5d |
| tip_verified | 2026-08-09 (`git rev-parse HEAD` → `7b44c5d66d7193eb1b05dde8a445b09032a88799`; `git log -1 --format=%ad,%s --date=short` → 2026-08-08 "docs(handoff): add GO-DASH-V2 Phase B handoff"; remote verified = `numtip/goffice2026`) |
| notes | Tip refreshed from 65360ea (stale, pre-refresh discovery) to 7b44c5d; prior note "docs(m365) GO-M365-3 partial baseline" superseded by later commits |

---

## 3. Current state

| Field | Value |
|-------|-------|
| summary | Active external project; tip 7b44c5d = GO-DASH-V2 Phase B handoff (2026-08-08); M365 baseline work earlier at 65360ea |
| as_of | 7b44c5d |
| detail_ref | CHANGELOG.md (project root) |

---

## 3.1 Canonical local path (decision 2026-08-09)

**Canonical local path: `F:\projectAi\goffice2026`** — established by this decision.

Evidence supporting `F:\projectAi\goffice2026` as canonical:
- `local_path` above (this adapter) is the machine-local clone path used by AI-OS tooling (`Compile-Prompt.ps1` resolves external canonical docs from it; `project-adapter/SPEC.md` requires `local_path` to exist on the machine claiming it).
- Repo verified present: `F:\projectAi\goffice2026\.git` exists; `git rev-parse HEAD` → `7b44c5d`; remote = `https://github.com/numtip/goffice2026.git` (matches `remote_url`).
- Project memory (`07_Memory/projects/goffice2026.md`) and prior releases (`10_Releases/v1.2.0-rc.1/`) reference the `F:` path.

Why `G:\ProjectAI\goffice2026` is NOT canonical:
- `G:\ProjectAI` exists but contains only `deer-flow`, `rae-nextjs`, `__OLD__rae-landing` — no `goffice2026` directory.
- No git repo, clone, or adapter evidence exists at that path; it cannot satisfy `project-adapter/SPEC.md` `local_path` validation.
- The `G:` path appeared only in the 2026-08-09 Stage 0 authorization brief; it is not backed by any repository record and is treated as a typo/outdated reference. Stage 0 evidence (`06_Research/pilots/v1.6-hermes/goffice2026/`) was therefore collected from `F:\projectAi\goffice2026`.

**Action:** all AI-OS references must use `F:\projectAi\goffice2026`. Any brief naming another local path should be corrected before execution.

---

## 4. Canonical documents

Paths relative to project root `F:\projectAi\goffice2026`.

| role | path | required | notes |
|------|------|----------|-------|
| readme | README.md | true | Always |
| product | PRODUCT.md | true | Minimum product context |
| package | package.json | true | Identity/scripts only — do not dump deps |
| design | DESIGN.md | false | Task-only |
| changelog | CHANGELOG.md | false | Task-only / current-state detail_ref |
| constitution | docs/00-GREENOFFICE_PROJECT_CONSTITUTION.MD | false | Task-only |
| master_reference | docs/GOFFICE2026_NEW_PROJECT_MASTER_REFERENCE.md | false | Task-only — large; never default bootstrap |

---

## 5. Memory entry

| Field | Value |
|-------|-------|
| memory_path | 07_Memory/projects/goffice2026.md |

---

## 6. Bootstrap path

| Field | Value |
|-------|-------|
| ai_os_bootstrap | 09_SOP/AGENT_BOOTSTRAP.md |
| adapter_ref | 01_Projects/goffice2026/ADAPTER.md |
| project_entry | Follow AI-OS `09_SOP/AGENT_BOOTSTRAP.md`, then this adapter; open canonical documents from the external project root as needed. |
| extra_steps | Load memory at `07_Memory/projects/goffice2026.md` if present; do not copy external docs into the vault. |

---
