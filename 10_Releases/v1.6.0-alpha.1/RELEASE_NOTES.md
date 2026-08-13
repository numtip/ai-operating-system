# v1.6.0-alpha.1 release notes

This alpha turns the previously validated Hermes pilot into a reusable local
system. AI-OS supplies installation, policy and evidence; Hermes remains the
native memory/session/orchestration backend, and Obsidian opens that same
memory directory.

The Windows installer:

1. clones and verifies the exact Hermes source pin;
2. creates an isolated virtual environment with the Hermes MCP extra;
3. safely enables native memory and user-profile support;
4. installs a path-portable global launcher;
5. registers Git repositories under the selected project root;
6. installs Obsidian vault metadata into Hermes home;
7. merges the global Codex workflow and registers both MCP servers;
8. performs a protocol-level memory read test.

It does not install, read or copy provider credentials. Existing Hermes config,
Codex AGENTS instructions and Codex MCP configuration are backed up or merged.

One Codex restart is required after installation.
