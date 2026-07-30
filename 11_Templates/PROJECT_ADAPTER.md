# Project Adapter: {{PROJECT_ID}}

> Fill all required fields. Link paths only — do not paste project documentation.
> Spec: `03_Architecture/project-adapter/SPEC.md`

---

## 1. Metadata

| Field | Value |
|-------|-------|
| project_id | {{PROJECT_ID}} |
| display_name | {{DISPLAY_NAME}} |
| status | {{draft \| active \| paused \| done \| archived}} |
| owner | {{OWNER}} |
| adapter_version | 1.0 |
| location_kind | {{external \| in_vault}} |

---

## 2. Repository

### If location_kind = external

| Field | Value |
|-------|-------|
| local_path | {{ABSOLUTE_LOCAL_PATH}} |
| remote_url | {{https://github.com/...}} |
| default_branch | {{BRANCH}} |
| tip_commit | {{SHORT_SHA_OPTIONAL}} |
| notes | {{ONE_LINE_OPTIONAL}} |

### If location_kind = in_vault

| Field | Value |
|-------|-------|
| vault_path | {{01_Projects/.../}} |
| remote_url | {{OPTIONAL}} |
| default_branch | {{OPTIONAL}} |
| tip_commit | {{OPTIONAL}} |
| notes | {{ONE_LINE_OPTIONAL}} |

---

## 3. Current state

| Field | Value |
|-------|-------|
| summary | {{≤240 chars}} |
| as_of | {{YYYY-MM-DD or short SHA}} |
| detail_ref | {{path or URL — optional}} |

---

## 4. Canonical documents

Paths relative to **project root**. Do not embed bodies.

| role | path | required |
|------|------|----------|
| readme | README.md | true |
| product | PRODUCT.md | false |
| design | DESIGN.md | false |
| changelog | CHANGELOG.md | false |
| {{ROLE}} | {{RELATIVE_PATH}} | {{true\|false}} |

---

## 5. Memory entry

| Field | Value |
|-------|-------|
| memory_path | 07_Memory/projects/{{PROJECT_ID}}.md |

---

## 6. Bootstrap path

| Field | Value |
|-------|-------|
| ai_os_bootstrap | 09_SOP/AGENT_BOOTSTRAP.md |
| adapter_ref | 01_Projects/{{PROJECT_ID}}/ADAPTER.md |
| project_entry | Follow AI-OS `09_SOP/AGENT_BOOTSTRAP.md`, then this adapter; open canonical documents from the project root as needed. |
| extra_steps | {{optional short bullets; max 5}} |

---

## Checklist (author)

- [ ] Only the six surfaces above are filled
- [ ] No pasted PRODUCT / DESIGN / constitution / changelog bodies
- [ ] Paths resolve for this `location_kind`
- [ ] Memory entry is a thin pointer (or placeholder), not a doc mirror
