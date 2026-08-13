# Hermes + Obsidian Live Shared-Memory Deployment

**Date:** 2026-08-14

**Scope:** Local machine, all Git project repositories discovered below `F:\projectAi`

**Decision:** Use installed Hermes + Obsidian as the active agent-memory system. AI-OS must not develop a competing memory/session-search stack.

## Result

**LIVE_LOCAL_PASS**

- Hermes Agent v0.20.0 (2026.8.3) remains installed in the isolated repo-local venv.
- Global launcher: `C:\Users\prinya\AppData\Local\Microsoft\WindowsApps\hermes.ps1`.
- Shared native Hermes home: `C:\Users\prinya\AppData\Local\hermes`.
- Native bounded `MEMORY.md` and `USER.md` enabled and seeded through Hermes `MemoryStore`/`memory_tool`.
- Native FTS5 session search verified against real prior GOFFICE2026 and Document Center sessions with zero model calls.
- Hermes project registry contains 28 recursively discovered Git repositories/worktrees under `F:\projectAi`.
- Obsidian vault config and index note installed directly in the shared Hermes home.
- Codex global instructions installed at `C:\Users\prinya\.codex\AGENTS.md`; this applies in every repository.
- Codex MCP config contains `hermes-memory` and native `hermes-tools`, both enabled.

## Portable release

The validated host paths above are local evidence, not installer defaults.
Release `v1.6.0-alpha.1` adds
`scripts/Install-HermesObsidianMemory.ps1` and
`scripts/hermes-install.lock.json` so another Windows machine derives its own
user, runtime, Codex and project-root paths. The installer verifies the same
Hermes tag and immutable commit before configuring memory or clients.

Personal `MEMORY.md`, `USER.md`, `.env`, tokens and provider credentials are
not included in the repository or copied by the installer.

## Native-memory bridge

Hermes v0.20.0's bundled `hermes-tools` MCP server deliberately excludes `memory` and `session_search` because those tools normally require a running Hermes agent loop. The installed source comments and the migration description disagree on this point.

A narrow bridge therefore exposes only:

- `hermes_memory` — reads/writes the installed Hermes `MemoryStore`; native limits, duplicate handling, locking and security scanning remain authoritative.
- `hermes_session_search` — calls Hermes' native SQLite/FTS5 session-search implementation; no replacement database and no LLM summary path.

This bridge adds no separate memory format, store, index or search engine.

## Verification

| Check | Result |
|---|---|
| Global `hermes --version` | PASS — v0.20.0 |
| `hermes memory status` | PASS — memory injection, user profile and memory tool enabled |
| Native memory files | PASS — `MEMORY.md` and `USER.md` contain the confirmed operating decision |
| Native session browse | PASS — prior real sessions returned from `state.db` |
| Project registry | PASS — 28 entries |
| MCP protocol initialization | PASS |
| MCP tool list | PASS — `hermes_memory`, `hermes_session_search` |
| MCP native-memory read | PASS |
| Codex MCP list | PASS — `hermes-memory` and `hermes-tools` enabled |
| Obsidian vault | PASS — valid JSON and vault index present; desktop process opened against `C:\Users\prinya\AppData\Local\hermes` and remained running |
| Portable installer plan tests | PASS — 24/24 assertions |
| Portable installer live end-to-end | PASS — source pin, config merge, 28 projects, Codex MCP, launcher and native-memory protocol |

## Dependencies and safety

- Installed Hermes' own pinned MCP extra: `mcp==1.28.1`, `starlette==1.3.1`.
- No credentials were printed, copied into the repository or added to memory.
- Existing Codex config and global AGENTS file were backed up under `C:\Users\prinya\.codex\backups\` before changes.
- No project repository files outside AI-OS were modified; repositories were registered only in Hermes' native `projects.db`.
- Current Codex sessions must restart once to load the newly added global instructions and MCP servers.

## Operating rule

Start non-trivial tasks with bounded Hermes memory, use native FTS5 session search before broad history/repository scans, and save only compact durable facts at task close. Obsidian is the human editing/review interface over those same files.
