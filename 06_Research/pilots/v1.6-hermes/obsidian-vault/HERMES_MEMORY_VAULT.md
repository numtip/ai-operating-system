# Hermes Memory Vault

This vault is the human interface for the native Hermes persistent-memory home.

## Live memory

- [[memories/MEMORY|Agent memory]]
- [[memories/USER|User profile]]
- `state.db` — Hermes session history and FTS5 session search (managed by Hermes)
- `projects.db` — Hermes project registry (managed by Hermes)
- `sessions/` — Hermes session artifacts (managed by Hermes)
- `skills/` — Hermes native procedural memory (managed by Hermes)

## Operating rule

Hermes owns runtime memory, session search, and skills. Obsidian edits and reviews the same native Markdown files. AI-OS must not create a competing memory store.
