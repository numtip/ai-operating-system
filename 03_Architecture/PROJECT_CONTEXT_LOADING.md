# Project Context Loading

Ordered load rules for agents. Stop when enough context exists. Do not scan the whole vault.

## Required order

| # | Source | Path / rule |
|---|--------|-------------|
| 1 | System memory | [../07_Memory/SYSTEM_MEMORY.md](../07_Memory/SYSTEM_MEMORY.md) |
| 2 | Current state | [../07_Memory/CURRENT_STATE.md](../07_Memory/CURRENT_STATE.md) |
| 3 | Project memory | [../07_Memory/PROJECT_MEMORY.md](../07_Memory/PROJECT_MEMORY.md) and/or `07_Memory/projects/<id>/` for the active project only |
| 4 | Relevant ADRs | Prefer [../07_Memory/DECISION_MEMORY.md](../07_Memory/DECISION_MEMORY.md), then matching files under `04_ADR/` |
| 5 | Task context | Task brief / [TASK_CONTEXT](../11_Templates/context/TASK_CONTEXT.md) package for this session |

## Minimal required-read policy

**Always read (every session start):**

1. `07_Memory/SYSTEM_MEMORY.md`
2. `07_Memory/CURRENT_STATE.md`

**Read only if needed for the task:**

- Project memory for the scoped project
- ADRs cited by DECISION_MEMORY or the task brief
- Task / context package files
- Operating rules when ownership or gates are unclear: [../07_Memory/OPERATING_RULES.md](../07_Memory/OPERATING_RULES.md)

**Do not read by default:**

- Full session history, unrelated projects, entire `04_ADR/` tree, chat transcripts, or bulk Knowledge dumps

## After load

Proceed via [../09_SOP/AGENT_BOOTSTRAP.md](../09_SOP/AGENT_BOOTSTRAP.md) (Git inspect → execute). Emit readiness with [../09_SOP/SESSION_READINESS.md](../09_SOP/SESSION_READINESS.md).
