# 12_Indexes

Lightweight knowledge indexes for AI-OS discovery and agent bootstrap routing.

## Purpose

Provide **path/tag references** to canonical documents, projects, ADRs, and skills so agents can locate material without scanning the full tree.

Indexes are **references only** — never duplicate document bodies here.

## Files

| File | Contents |
|------|----------|
| `knowledge_index.json` | Canonical knowledge / memory / dashboard docs |
| `project_index.json` | Projects under `01_Projects/` |
| `adr_index.json` | Architecture Decision Records under `04_ADR/` |
| `skill_index.json` | Skills under `08_Skills/` |

## Schema

Each index JSON includes:

- `schema_version` — string (currently `"1.0"`)
- `entries` — array of `{ id, title, path, tags[] }`
- optional top-level `note` — human hint (e.g. empty project list)

`path` values are relative to the repo root and use forward slashes.

## No content duplication

- Store id, title, path, and tags only.
- Do not embed full markdown bodies, excerpts, or vector embeddings.
- Broken paths fail validation (`scripts/validate-indexes.ps1`).

## Regenerate

From repo root:

```powershell
pwsh -File scripts/generate-indexes.ps1
# or Windows PowerShell 5.x:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/generate-indexes.ps1
```

Validate:

```powershell
pwsh -File scripts/validate-indexes.ps1
```

See also: [ADR-0006](../04_ADR/ADR-0006-file-based-indexes-before-vector.md).
