# Project Memory

How durable project context is stored and used.

## Location

Project-scoped memory files live under:

[`projects/`](projects/)

One folder or file set per active project (as needed). Keep entries concise and linkable.

## What belongs here

- Goals, constraints, and current focus for a named project
- Pointers to Knowledge, Architecture, Tasks, and ADRs for that project
- Open risks / next actions that must survive across sessions

## What does not

- System-wide facts → [SYSTEM_MEMORY](SYSTEM_MEMORY.md)
- Session narrative → `sessions/YYYY/` + [SESSION_INDEX](SESSION_INDEX.md)
- Decision bodies → `04_ADR/` via [DECISION_MEMORY](DECISION_MEMORY.md)

## Usage

1. Bootstrap: load only the project memory relevant to the task
2. Close: update that project file if state changed
3. Prefer links over copying content from elsewhere
