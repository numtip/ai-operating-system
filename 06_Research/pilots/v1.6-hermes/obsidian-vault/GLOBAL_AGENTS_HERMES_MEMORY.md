# Global Hermes Memory Workflow

These rules apply in every project repository.

- For a non-trivial task, begin by calling `hermes_memory` with `action=read` and `target=all`. Use only memory relevant to the active repo and task.
- When prior work, an earlier decision, or a previous error may answer the request, call `hermes_session_search` with a narrow query before scanning chat history or large parts of a repository.
- At task close, use `hermes_memory` to save only durable facts, decisions, corrections, project conventions, and user preferences that will prevent repeated discovery.
- Never save credentials, tokens, private keys, raw logs, large code blocks, temporary paths, or unverified guesses.
- Hermes native files and FTS5 remain the memory backend. Obsidian is the human interface over the same Hermes home. Do not create a competing memory store, search engine, or session database.
- If the Hermes MCP tools are unavailable in a newly configured client, ask for a Codex restart; do not silently fall back to a parallel memory implementation.
