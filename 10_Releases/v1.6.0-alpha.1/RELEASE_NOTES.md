# v1.6.0-alpha.1 release notes

This alpha turns the previously validated Hermes pilot into a reusable local
system. AI-OS supplies installation, policy and evidence; Hermes remains the
native memory/session/orchestration backend, and Obsidian opens that same
memory directory.

The Windows installer:

1. clones and verifies the exact Hermes source pin;
2. creates an isolated virtual environment with the Hermes MCP extra;
3. safely enables native memory and user-profile support;
4. seeds the bundled `SKILL.md` catalog through Hermes' native sync command;
5. verifies the Hermes Agent and Obsidian skills in the shared home;
6. installs a path-portable global launcher;
7. registers Git repositories under the selected project root;
8. installs Obsidian vault metadata into Hermes home;
9. merges the global Codex workflow and registers both MCP servers;
10. performs a protocol-level memory read test.

It also sets the non-secret `OBSIDIAN_VAULT_PATH` value in the local Hermes
`.env` so the bundled Obsidian skill resolves the same vault. Existing `.env`
content is preserved and backed up; it is never committed.

It does not install, read or copy provider credentials. Existing Hermes config,
Codex AGENTS instructions and Codex MCP configuration are backed up or merged.

One Codex restart is required after installation.
