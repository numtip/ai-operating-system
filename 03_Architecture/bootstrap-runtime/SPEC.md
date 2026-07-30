# Bootstrap Runtime Spec

**Version:** 1.2  
**Status:** Spec-only  
**Kind:** Deterministic file workflow (no LLM)

## Goal

Given a **project name**, produce an **ordered context package** and a short **bootstrap summary** with the fewest file reads possible.

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project_name` | string | yes | Folder name or index `id` / `title` match under `01_Projects/` |
| `repo_root` | path | no | Defaults to AI-OS vault root |
| `write_simulation` | bool | no | If true and adapter exists, write `last-bootstrap-simulation.md` |

## Outputs

| Artifact | Format | Description |
|----------|--------|-------------|
| Bootstrap summary | Markdown (see [OUTPUT_SCHEMA.md](OUTPUT_SCHEMA.md)) | Status, match, would-read count, blockers |
| Ordered context package | Markdown or JSON fields | Ordered list of paths to read next |

## Algorithm (ordered)

### 1. Read indexes

1. Load `12_Indexes/project_index.json` (required).
2. Optionally peek index metadata only from:
   - `12_Indexes/knowledge_index.json` (for canonical memory paths)
   - `12_Indexes/adr_index.json` (ids/paths only — do not open ADR bodies yet)
3. **Do not** open project files before the index lookup completes.

**Stop (hard fail):** `project_index.json` missing or unparseable → emit summary with `status: blocked`, `blocker: missing_index`.

### 2. Locate canonical files

1. Resolve `project_name` against `project_index.entries`:
   - Match `id`, folder segment of `path`, or case-insensitive `title`.
2. Derive project root: `01_Projects/<resolved_folder>/`.
3. Locate, if present (existence check only at this step):
   - `ADAPTER.md` (adapter pointer; do not follow external trees)
   - `README.md`
   - `Architecture/`, `Blueprint/`, `Tasks/` (directory presence flags)
4. If no index match, attempt direct path `01_Projects/<project_name>/` as fallback.

**Stop (soft fail):** No index match and no folder → `status: not_found`. Still emit empty ordered package + summary.

### 3. Load minimum context

Read **bodies** only in this order; skip missing optional paths:

| Order | Path | Required |
|-------|------|----------|
| 1 | `07_Memory/SYSTEM_MEMORY.md` | yes (session memory) |
| 2 | `07_Memory/CURRENT_STATE.md` | yes |
| 3 | `01_Projects/<name>/ADAPTER.md` | no |
| 4 | `01_Projects/<name>/README.md` | no |
| 5 | Project memory if cited by adapter or README (`07_Memory/projects/<id>/` or `07_Memory/PROJECT_MEMORY.md`) | no |

**Do not** deep-read ADRs, Knowledge dumps, session history, or external paths from the adapter in this runtime.

**Stop (enough context):** After steps 1–4 of the table (or first missing required memory file recorded as blocker), proceed to summary. Do not search the vault for more files.

### 4. Produce bootstrap summary

Emit:

1. Bootstrap summary (Markdown or JSON fields per [OUTPUT_SCHEMA.md](OUTPUT_SCHEMA.md))
2. Ordered context package listing **next** reads for the agent (template: [../../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md](../../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md))

Optional write (simulation only):

- If `ADAPTER.md` exists and write is enabled → `01_Projects/<name>/last-bootstrap-simulation.md`
- Else → stdout only
- **Forbidden:** `06_Research/pilots/_generated/` and any path outside the vault project folder for writes

## Stop conditions

| Condition | `status` | Action |
|-----------|----------|--------|
| Index missing/invalid | `blocked` | Stop; no package assembly beyond error fields |
| Project not found | `not_found` | Stop after index read; empty package |
| Required memory file missing | `degraded` | Continue with available paths; list blockers |
| Minimum context loaded | `ready` | Emit summary + package; stop |
| Adapter points outside vault | `ready_local_only` | Note external path; **do not** read or modify it |

## Token-reduction rules

1. **Index before file** — Resolve location from `12_Indexes/*` before opening project documents.
2. **Memory before search** — Prefer `07_Memory/SYSTEM_MEMORY.md` + `CURRENT_STATE.md` over glob/search.
3. **Adapter before tree walk** — If `ADAPTER.md` exists, use its declared canonical paths; do not recurse project folders.
4. **Existence before body** — Stat/list first; read bodies only for the minimum set.
5. **Summaries before ADRs** — Prefer `07_Memory/DECISION_MEMORY.md` citations over opening `04_ADR/*` (ADR bodies are out of bootstrap-runtime scope unless the ordered package explicitly lists one path).
6. **Hard read cap** — Bootstrap loads at most **6** file bodies. Additional paths go into the ordered package as *unread* next steps.
7. **No LLM** — Ranking and packaging are deterministic rules only.

## Simulation contract

`scripts/simulate-bootstrap.ps1 -ProjectName <name>` implements a dry-run of steps 1–4:

- Counts files it **would** read
- Does not call LLMs
- Does not modify external project trees
- Writes `last-bootstrap-simulation.md` only when adapter exists under the resolved project folder

## Constraints

- Spec-first; no Hermes; no DB
- Do not implement project-adapter package here
- Do not touch metrics, pilots, or `04_ADR` bodies from this runtime
