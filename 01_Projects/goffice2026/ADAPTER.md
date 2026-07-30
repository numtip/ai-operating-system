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
| tip_commit | 65360ea |
| notes | Tip at discovery: docs(m365) GO-M365-3 partial baseline / finish runbook |

---

## 3. Current state

| Field | Value |
|-------|-------|
| summary | Active external project; M365 baseline work recorded at tip 65360ea |
| as_of | 65360ea |
| detail_ref | CHANGELOG.md (project root) |

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
