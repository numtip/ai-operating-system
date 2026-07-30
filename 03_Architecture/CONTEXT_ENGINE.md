# Context Engine

AI-OS v1.1 foundation. File-based only — no database, no vector store, no runtime service.

## Chain

```text
Context → Memory → Task → Decision → Output
```

| Stage | Role | Artifact |
|-------|------|----------|
| **Context** | Assemble minimal working set | [CONTEXT_PACKAGE](../11_Templates/context/CONTEXT_PACKAGE.md) |
| **Memory** | Durable facts + live state | `07_Memory/` (SYSTEM, CURRENT_STATE, project) |
| **Task** | Scoped goal and write bounds | [TASK_CONTEXT](../11_Templates/context/TASK_CONTEXT.md) |
| **Decision** | Constraints from ADRs / policy | [DECISION_CONTEXT](../11_Templates/context/DECISION_CONTEXT.md) |
| **Output** | Deliverable + readiness report | [OUTPUT_CONTEXT](../11_Templates/context/OUTPUT_CONTEXT.md) |

## Principles

- **Files as truth** — Markdown + Git; agents read paths, not embeddings.
- **Minimal load** — Prefer summaries and indexes; deep-read only what the task needs.
- **Ordered assembly** — Follow [PROJECT_CONTEXT_LOADING.md](PROJECT_CONTEXT_LOADING.md).
- **Templates** — Copy scaffolds under [../11_Templates/context/](../11_Templates/context/).

## Bootstrap

Session start uses [../09_SOP/AGENT_BOOTSTRAP.md](../09_SOP/AGENT_BOOTSTRAP.md).

## Out of scope (this doc)

Hermes, DBs, secrets, compression pipelines, runtime services.
