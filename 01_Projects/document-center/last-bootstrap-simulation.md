# Bootstrap Summary: document-center

- **status:** ready
- **resolved_id:** project-document-center
- **project_root:** 01_Projects/document-center/
- **adapter_present:** true
- **files_would_read:** 5
- **files_read:** 4
- **generated_at:** 2026-07-30T15:50:12.1611479+07:00
- **schema_version:** 1.2

## Match
- index_hit: true
- matched_by: id

## Minimum context
| order | path | state |
|-------|------|-------|
| 1 | 07_Memory/SYSTEM_MEMORY.md | read |
| 2 | 07_Memory/CURRENT_STATE.md | read |
| 3 | 01_Projects/document-center/ADAPTER.md | read |
| 4 | 01_Projects/document-center/README.md | would_read |

## Blockers
- (none)

## Ordered context package (next reads)
1. `12_Indexes/project_index.json`
2. `07_Memory/SYSTEM_MEMORY.md`
3. `07_Memory/CURRENT_STATE.md`
4. `01_Projects/document-center/ADAPTER.md`
5. `01_Projects/document-center/README.md`
6. `07_Memory/DECISION_MEMORY.md` *(deferred unless needed)*

## Constraints
- Index before file; memory before search
- No LLM; no Hermes; no DB
- External adapter targets not followed
- Simulation write forbidden under `06_Research/pilots/`
