# Hermes Worker Instructions

These rules apply to Cursor and VS Code workers under a GPT/Codex Blueprint.

- For a non-trivial task, begin by calling `hermes_memory` with `action=read` and `target=all`. Use only memory relevant to the active repo and task.
- When prior work, an earlier decision, or a previous error may answer the request, call `hermes_session_search` with a narrow query before scanning chat history or large parts of a repository.
- Follow the GPT/Codex Blueprint. Do not change architecture, scope, or release.
- Before a task that matches a reusable workflow, call `skills_list` and load the relevant native Hermes `SKILL.md` with `skill_view`.
- Worker must never write durable Hermes memory. Do not call `hermes_memory` write actions (`add`, `replace`, `remove`) in any case. Send `memory_candidates` to GPT/Codex for review and approval before any durable memory write occurs.
- Never include credentials, tokens, private keys, raw logs, large code blocks, temporary paths, or unverified guesses in `memory_candidates`.
- Hermes native files and FTS5 remain the memory backend. Do not create a competing memory store, search engine, or session database.
