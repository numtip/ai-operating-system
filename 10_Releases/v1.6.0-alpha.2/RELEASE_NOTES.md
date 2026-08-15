# v1.6.0-alpha.2 release notes

This alpha adds Cursor and VS Code adapters to the existing Hermes +
Obsidian installer. Hermes remains the native memory backend. AI-OS does
not create a parallel store.

The Windows installer still performs the v1.6.0-alpha.1 steps, and also:

1. merges `hermes-memory` and `hermes-tools` into existing Cursor and VS Code user MCP configs;
2. installs a Cursor local plugin under `plugins/local/ai-os-hermes-worker` with a global worker rule;
3. installs VS Code user instruction files that send `memory_candidates` to GPT/Codex;
4. removes only a recognized AI-OS legacy `~/.cursor/rules/hermes-worker.mdc`; customized rules are preserved;
5. runs offline protocol smoke for memory and skills MCP tools.

MCP and instruction writes compare desired content with the on-disk file.
A backup and write happen only when the content changes.

The installer may read and back up existing local Hermes/Codex/Cursor/VS Code
config, including files that contain credentials. It must not print, export,
or commit credentials, tokens, API keys, or `.env` contents. Magnific and
other existing MCP servers are preserved.

Reload Cursor (Developer: Reload Window) so the local plugin is discovered.
Reload VS Code after the same install. One Codex restart is still required
when Codex MCP is configured.
