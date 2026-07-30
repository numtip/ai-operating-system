# Operating Rules

Agent rules for AI Operating System. Read at session start via [SESSION_BOOTSTRAP](SESSION_BOOTSTRAP.md).

## Token reduction

- Prefer memory files over chat history and full-repo scans.
- Read only what the task needs; stop when enough context exists.
- Summarize, then deep-read; never dump large trees into context.

## Targeted reads

1. [SYSTEM_MEMORY](SYSTEM_MEMORY.md) + [CURRENT_STATE](CURRENT_STATE.md)
2. Relevant project/session memory and ADRs ([DECISION_MEMORY](DECISION_MEMORY.md))
3. Task-specific Knowledge / Architecture / SOP paths only

## Memory before history

- Durable facts live in Memory. Do not re-derive from past chat.
- Update Memory at close ([SESSION_CLOSE](SESSION_CLOSE.md)); do not leave state only in conversation.

## Ownership and approvals

| Action | Owner / gate |
|--------|----------------|
| Commits | Head Agent only |
| Push, prod, deploy, secrets | Human approval required |
| Architecture / policy decisions | ADR in `04_ADR/` + index in [DECISION_MEMORY](DECISION_MEMORY.md) |

## Session lifecycle

- **Start:** [SESSION_BOOTSTRAP](SESSION_BOOTSTRAP.md)
- **End:** [SESSION_CLOSE](SESSION_CLOSE.md)
- **Index:** [SESSION_INDEX](SESSION_INDEX.md)
