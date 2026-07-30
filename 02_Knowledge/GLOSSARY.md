# Glossary

Short definitions for AI-OS v1. Prefer linking here instead of redefining.

### ADR
Architecture Decision Record — durable rationale for an important choice. Stored under `04_ADR/`.

### Memory
Persistent facts and live state under `07_Memory/` (system memory, current state, sessions, project memory). Read before chat history.

### SOP
Standard Operating Procedure — repeatable how-to under `09_SOP/`, usually from `11_Templates/`.

### Session Handoff
End-of-session note capturing what changed, open work, and next steps. Indexed in `07_Memory/SESSION_INDEX.md`; files under `07_Memory/sessions/YYYY/`.

### Head Agent
Single coordinating agent responsible for integration, validation, commits, and final reporting. Specialists do scoped work only.

### Local-first
Prefer local Obsidian + Git workflows before remote orchestration or VPS. Phase 1 constraint; see ADRs and [../03_Architecture/ARCHITECTURE_OVERVIEW.md](../03_Architecture/ARCHITECTURE_OVERVIEW.md).
