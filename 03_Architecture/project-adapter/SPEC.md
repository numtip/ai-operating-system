# Project Adapter — Specification

**Status:** Active  
**Version:** 1.0  
**Surfaces:** Metadata | Repository | Current state | Canonical documents | Memory entry | Bootstrap path

Adapters are pointer documents. Validation fails if any surface embeds full project documentation.

---

## 1. Metadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project_id` | string | yes | Stable id (slug), e.g. `goffice2026` |
| `display_name` | string | yes | Human-readable name |
| `status` | enum | yes | `draft` \| `active` \| `paused` \| `done` \| `archived` |
| `owner` | string | no | Owner or team label |
| `adapter_version` | string | yes | Spec version this adapter conforms to (e.g. `1.0`) |
| `location_kind` | enum | yes | `external` \| `in_vault` |

### Validation

- `project_id` must be lowercase slug `[a-z0-9][a-z0-9_-]*`
- `location_kind` must match Repository rules below
- No free-form product narrative beyond these fields

---

## 2. Repository

### External projects (`location_kind: external`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `local_path` | absolute path | yes* | Machine-local clone/checkout path |
| `remote_url` | URL | yes* | Canonical remote (e.g. GitHub) |
| `default_branch` | string | yes | Branch agents should assume |
| `tip_commit` | string | no | Short SHA at last discovery (informational; may go stale) |
| `notes` | string | no | One short line only |

\*At least one of `local_path` or `remote_url` is required; both preferred when known.

### In-vault projects (`location_kind: in_vault`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `vault_path` | vault-relative path | yes | Path under AI-OS vault root (e.g. `01_Projects/foo/`) |
| `remote_url` | URL | no | Optional if also mirrored remotely |
| `default_branch` | string | no | If git-backed |
| `tip_commit` | string | no | Informational |
| `notes` | string | no | One short line only |

### Validation

- Paths must resolve:
  - `local_path`: must exist as a directory when validating on a machine that claims the path
  - `vault_path`: must exist under the AI-OS vault root
- `remote_url` if present must be `https://` or `git@` form (no secrets in URL)
- Do not put credentials, tokens, or private clone URLs with embedded secrets
- External adapters MUST NOT treat `01_Projects/<id>/` as the source of truth for product docs

---

## 3. Current state

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `summary` | string | yes | ≤ 240 characters; one-line / short status |
| `as_of` | date or commit | no | When the summary was recorded (`YYYY-MM-DD` or short SHA) |
| `detail_ref` | path or URL | no | Pointer to fuller status (project CHANGELOG, memory, etc.) — not inline body |

### Validation

- `summary` must not exceed 240 characters
- No multi-section status reports inside the adapter
- Prefer `detail_ref` over expanding `summary`

---

## 4. Canonical documents

List of project-owned documents. Each entry:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `role` | string | yes | Stable role key, e.g. `readme`, `product`, `design`, `changelog`, `constitution`, `master_reference` |
| `path` | relative path | yes | Path relative to **project root** (external: repo root; in-vault: `vault_path`) |
| `required` | boolean | yes | Whether absence fails validation |

### Validation

- `path` must resolve relative to project root when the project is available
- **No embedded full docs** — only path + role
- Adapter and `01_Projects/<id>/` pointer files must not paste document bodies
- Duplicate `role` values are not allowed in one adapter
- Recommended core roles (not all required for every project): `readme`, `product`, `design`, `changelog`

---

## 5. Memory entry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `memory_path` | vault-relative path | yes | AI-OS memory file for this project, e.g. `07_Memory/projects/<project_id>.md` |

### Validation

- Path must be under `07_Memory/`
- Path should include `project_id` for discoverability
- File may be a thin placeholder; must not duplicate canonical project docs
- Do not inline session history into the adapter

---

## 6. Bootstrap path

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ai_os_bootstrap` | vault-relative path | yes | Usually `09_SOP/AGENT_BOOTSTRAP.md` |
| `adapter_ref` | vault-relative path | yes | Path to this adapter file |
| `project_entry` | string | yes | Short instruction: follow AI-OS bootstrap, then this adapter, then open canonical docs as needed |
| `extra_steps` | list of strings | no | Optional short bullets (no pasted runbooks) |

### Validation

- `ai_os_bootstrap` and `adapter_ref` must resolve in the vault
- `extra_steps` items ≤ 120 characters each; max 5 items
- Must not embed full SOP or project runbook text

---

## Cross-cutting validation rules

1. **Paths must resolve** — every required path field that applies to the `location_kind` must exist at validation time (Head-owned validators).
2. **No embedded full docs** — adapter body is fields and links only; reject pasted PRODUCT/DESIGN/constitution/CHANGELOG content.
3. **External vs in-vault**
   - `external`: truth is outside the vault; `01_Projects/<id>/` holds adapter + short README only
   - `in_vault`: truth is under `vault_path`; adapter still must not duplicate docs already at that path
4. **Link-don’t-copy** — see [README.md](README.md)
5. **Secrets** — never store API keys, tokens, or private credentials in adapter files

---

## File layout (convention)

```
01_Projects/<project_id>/
  ADAPTER.md          # filled adapter (this schema)
  README.md           # short pointer page only
07_Memory/projects/
  <project_id>.md     # thin memory entry
```

Template: [../../11_Templates/PROJECT_ADAPTER.md](../../11_Templates/PROJECT_ADAPTER.md)
