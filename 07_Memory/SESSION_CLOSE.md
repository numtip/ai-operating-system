# Session Close

Protocol for ending a work session. Persist state; do not leave facts only in chat.

## 1. Update living memory

- [CURRENT_STATE](CURRENT_STATE.md) — phase, last session, open items, blockers
- [SESSION_INDEX](SESSION_INDEX.md) — add/update the session row
- [DECISION_MEMORY](DECISION_MEMORY.md) — only if an ADR was added or changed

## 2. Write session handoff

Create:

`sessions/YYYY/YYYY-MM-DD-topic.md`

Suggested sections: goal, done, decisions, open items, next, verdict.

## 3. Propose commit (Head Agent)

- Stage relevant Memory (and related) files
- Propose a concise commit message
- **Head Agent owns the commit**
- **Do not push** without human approval
- No prod / deploy / secrets without human approval

## 4. Stop cleanly

Confirm CURRENT_STATE and SESSION_INDEX match the handoff. Leave Hermes/VPS/install work for approved Phase 2+.

Bootstrap next time: [SESSION_BOOTSTRAP](SESSION_BOOTSTRAP.md).
