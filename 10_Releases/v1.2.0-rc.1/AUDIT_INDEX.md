# AUDIT_INDEX — AI-OS v1.2.0-rc.1

**Date:** 2026-07-30  
**Scope:** `12_Indexes/{project,knowledge,adr,skill}_index.json`  
**Mode:** Read-only (no index regeneration)  
**Overall:** **PASS**

## Summary counts

| Metric | Count |
|--------|------:|
| Entries (all indexes) | 22 |
| Orphans (path missing on disk) | 0 |
| Duplicate ids (within each index) | 0 |
| Duplicate paths (within each index) | 0 |
| JSON parse failures | 0 |
| Broken references | 0 |

## Per-index

| Index | Parse | Entries | Orphans | Dup ids | Dup paths |
|-------|-------|--------:|--------:|--------:|----------:|
| `project_index.json` | OK | 1 | 0 | 0 | 0 |
| `knowledge_index.json` | OK | 10 | 0 | 0 | 0 |
| `adr_index.json` | OK | 10 | 0 | 0 | 0 |
| `skill_index.json` | OK | 1 | 0 | 0 | 0 |

### Notes

- **JSON parse:** All four files parse successfully; each has `schema_version` `1.0` and an `entries` array.
- **Orphans:** Every `path` resolves under the repo root (files or directories, trailing `/` allowed).
- **Duplicates:** No repeated `id` or normalized `path` within any single index.
- **Broken references:** No inter-entry ref fields (`refs` / `references` / `related` / etc.). Path targets are the only references; all valid.
- **`skill_index`:** Placeholder entry `skills-root` → `08_Skills/` (directory exists). Documented as placeholder until skills are authored — not treated as a defect for RC.

## Coverage checks

| Check | Result |
|-------|--------|
| `adr_index` covers ADR-0001..0010 | **Yes** — ids `adr-0001` … `adr-0010`; all ten ADR markdown paths exist |
| `project_index` includes goffice2026 | **Yes** — id `project-goffice2026`, path `01_Projects/goffice2026/` (directory exists) |

On-disk ADRs under `04_ADR/`: ADR-0001..0010 plus `ADR-TEMPLATE.md` (template intentionally not indexed).

## `scripts/validate-indexes.ps1`

```
RESULT: PASS
exit code: 0
```

All checks reported PASS: directory present, JSON parse, schema_version, and every entry path.

## Verdict

**PASS** — indexes are parseable, paths resolve, no duplicate ids/paths within indexes, ADR-0001..0010 and goffice2026 are present, validator script passes.
