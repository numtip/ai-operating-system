# Bootstrap Context Package: {{PROJECT_NAME}}

## Goal
Assemble minimum context for project `{{PROJECT_NAME}}` (index → canonical files → memory → summary).

## Chain refs
- Runtime: [../../03_Architecture/bootstrap-runtime/SPEC.md](../../03_Architecture/bootstrap-runtime/SPEC.md)
- Session bootstrap: [../../09_SOP/AGENT_BOOTSTRAP.md](../../09_SOP/AGENT_BOOTSTRAP.md)
- Project SOP: [../../09_SOP/PROJECT_BOOTSTRAP.md](../../09_SOP/PROJECT_BOOTSTRAP.md)
- General package: [CONTEXT_PACKAGE.md](CONTEXT_PACKAGE.md)

## Ordered reads
Read **in this order**. Stop when enough context exists (see SPEC stop conditions).

1. `12_Indexes/project_index.json` *(index only — locate, do not treat as narrative)*
2. `07_Memory/SYSTEM_MEMORY.md`
3. `07_Memory/CURRENT_STATE.md`
4. `01_Projects/{{PROJECT_FOLDER}}/ADAPTER.md` *(if present)*
5. `01_Projects/{{PROJECT_FOLDER}}/README.md` *(if present)*
6. `{{PROJECT_MEMORY_PATH_OR_N_A}}`
7. `07_Memory/DECISION_MEMORY.md` *(citations only; open listed ADRs later if needed)*
8. `{{TASK_CONTEXT_PATH_OR_N_A}}`

## Already loaded
- {{PATH_OR_NONE}}

## Deferred (do not read during bootstrap)
- Full `04_ADR/` tree
- Unrelated `01_Projects/*`
- Session history under `07_Memory/sessions/`
- External trees referenced by adapter
- Knowledge dumps / bulk Research

## Write bounds
- In: `{{PATH}}`
- Out of scope: `project-adapter/`, external repos, `06_Research/pilots/_generated/`, `04_ADR` (unless task-owned)

## Constraints
- Index before file; memory before search
- No LLM required to build this package
- No Hermes; no DB
- Max 6 file bodies during bootstrap load; remainder stay listed unread
