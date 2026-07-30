# Session Bootstrap

Protocol for starting a work session. Keep context small.

## Read only (in order)

1. Repo `README.md` (if present)
2. [OPERATING_RULES](OPERATING_RULES.md)
3. [SYSTEM_MEMORY](SYSTEM_MEMORY.md)
4. [CURRENT_STATE](CURRENT_STATE.md)
5. Then **only as needed**:
   - [SESSION_INDEX](SESSION_INDEX.md) / latest session handoff
   - [DECISION_MEMORY](DECISION_MEMORY.md) + relevant ADRs
   - [PROJECT_MEMORY](PROJECT_MEMORY.md) / `projects/` entry for the task
   - Specific Knowledge / Architecture / task files

Do **not** load full chat history or scan the whole tree by default.

## Inspect git

```text
git status
git log -5 --oneline
```

Note branch, dirty files, and recent commits. Do not commit unless Head Agent owns the action.

## Summarize baseline

Before editing, state briefly:

- Phase / current goal (from CURRENT_STATE)
- Relevant open items or blockers
- Scope for this session

Then proceed. Close with [SESSION_CLOSE](SESSION_CLOSE.md).
