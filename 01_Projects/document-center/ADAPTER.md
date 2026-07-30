# Project Adapter: document-center

> Spec: `03_Architecture/project-adapter/SPEC.md`  
> Minimum adapter for AI-OS v1.3 Prompt Compiler pilot. Pointers only.

---

## 1. Metadata

| Field | Value |
|-------|-------|
| project_id | document-center |
| display_name | Document Center |
| status | draft |
| owner | numtip |
| adapter_version | 1.0 |
| location_kind | in_vault |

---

## 2. Repository

| Field | Value |
|-------|-------|
| vault_path | 01_Projects/document-center/ |
| remote_url | |
| default_branch | |
| tip_commit | |
| notes | Minimum pilot adapter; external product docs not yet linked |

---

## 3. Current state

| Field | Value |
|-------|-------|
| summary | Draft in-vault pilot entry for publication pipeline readiness inspection |
| as_of | 2026-07-30 |
| detail_ref | 01_Projects/document-center/README.md |

---

## 4. Canonical documents

Paths relative to vault project root `01_Projects/document-center/`.

| role | path | required | notes |
|------|------|----------|-------|
| readme | README.md | true | Always |
| product | PRODUCT.md | false | Not authored yet |
| pipeline | PIPELINE.md | false | Publication pipeline notes (optional) |

---

## 5. Memory entry

| Field | Value |
|-------|-------|
| memory_path | 07_Memory/projects/document-center.md |

---

## 6. Bootstrap path

| Field | Value |
|-------|-------|
| ai_os_bootstrap | 09_SOP/AGENT_BOOTSTRAP.md |
| adapter_ref | 01_Projects/document-center/ADAPTER.md |
| project_entry | Follow AI-OS bootstrap, then this adapter; do not load goffice2026 context |
| extra_steps | Load memory at `07_Memory/projects/document-center.md` if present |
