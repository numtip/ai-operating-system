# Bootstrap Runtime Output Schema

Canonical fields for the **bootstrap summary** and **ordered context package**. Emit as Markdown (preferred for agents) or JSON with the same keys.

## Bootstrap summary

### Markdown shape

```markdown
# Bootstrap Summary: {{project_name}}

- **status:** ready | ready_local_only | degraded | not_found | blocked
- **resolved_id:** {{index_id_or_empty}}
- **project_root:** {{repo_relative_path_or_empty}}
- **adapter_present:** true | false
- **files_would_read:** {{integer}}
- **files_read:** {{integer}}
- **generated_at:** {{ISO-8601_or_local}}

## Match
- index_hit: true | false
- matched_by: id | path | title | folder_fallback | none

## Minimum context
| order | path | state |
|-------|------|-------|
| 1 | 07_Memory/SYSTEM_MEMORY.md | read | missing | skipped |
| … | … | … |

## Blockers
- {{blocker_code}}: {{message}}

## Next
- ordered_package: see Ordered Context Package below (or linked path)
```

### JSON fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | yes | `"1.2"` |
| `kind` | string | yes | `"bootstrap_summary"` |
| `project_name` | string | yes | Input name |
| `status` | enum | yes | `ready` \| `ready_local_only` \| `degraded` \| `not_found` \| `blocked` |
| `resolved_id` | string \| null | yes | Index entry `id` if matched |
| `project_root` | string \| null | yes | Repo-relative folder ending with `/` |
| `adapter_present` | boolean | yes | `ADAPTER.md` exists |
| `match.index_hit` | boolean | yes | |
| `match.matched_by` | enum | yes | `id` \| `path` \| `title` \| `folder_fallback` \| `none` |
| `minimum_context` | array | yes | Objects: `{ order, path, state }` where `state` ∈ `read` \| `missing` \| `skipped` \| `would_read` |
| `files_would_read` | integer | yes | Count of paths in load plan |
| `files_read` | integer | yes | Bodies actually opened (simulation may equal would_read for index+existence only) |
| `blockers` | array | yes | Objects: `{ code, message }` (empty if none) |
| `ordered_package_ref` | string \| null | no | Path to package artifact if written |
| `generated_at` | string | yes | Timestamp |

### Blocker codes

| Code | Meaning |
|------|---------|
| `missing_index` | `project_index.json` absent or invalid |
| `project_not_found` | No index/folder match |
| `missing_system_memory` | Required memory file absent |
| `missing_current_state` | Required state file absent |
| `external_adapter_target` | Adapter references a path outside the vault (do not follow) |

## Ordered context package

Companion to [../../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md](../../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md).

### Markdown fields

| Section | Content |
|---------|---------|
| Title | `# Bootstrap Context Package: {{project_name}}` |
| Goal | One-line bootstrap goal |
| Ordered reads | Numbered list — **read in this order only** |
| Already loaded | Paths consumed during bootstrap (do not re-read unless stale) |
| Deferred | Paths known but not loaded (ADR ids, Knowledge, etc.) |
| Write bounds | In / out of scope for the upcoming task |
| Constraints | Hard rules carried forward |

### JSON fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | yes | `"1.2"` |
| `kind` | string | yes | `"bootstrap_context_package"` |
| `project_name` | string | yes | |
| `goal` | string | yes | |
| `ordered_reads` | array | yes | Objects: `{ order, path, reason, required }` |
| `already_loaded` | string[] | yes | Paths read in bootstrap |
| `deferred` | string[] | yes | Known but unread |
| `write_bounds.in` | string[] | yes | |
| `write_bounds.out` | string[] | yes | |
| `constraints` | string[] | yes | |

### Default ordered_reads (when project resolves)

| order | path | reason | required |
|-------|------|--------|----------|
| 1 | `07_Memory/SYSTEM_MEMORY.md` | system memory | true |
| 2 | `07_Memory/CURRENT_STATE.md` | live state | true |
| 3 | `01_Projects/<name>/ADAPTER.md` | adapter | false |
| 4 | `01_Projects/<name>/README.md` | project entry | false |
| 5 | `07_Memory/DECISION_MEMORY.md` | decision index | false |
| 6 | task brief / `11_Templates/context/TASK_CONTEXT.md` instance | task scope | false |

## Emission rules

1. Summary **always** emitted (even on `blocked` / `not_found`).
2. Package `ordered_reads` may be empty when `status` is `blocked` or `not_found`.
3. Prefer Markdown for human/agent stdout; JSON optional for tooling.
4. Simulation write target (adapter present only): `01_Projects/<name>/last-bootstrap-simulation.md` containing both summary and package sections.
