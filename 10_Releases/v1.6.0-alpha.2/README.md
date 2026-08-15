# v1.6.0-alpha.2

Cursor and VS Code Hermes MCP adapters on the existing Windows installer.

This pack does not replace [v1.6.0-alpha.1](../v1.6.0-alpha.1/). It adds
IDE adapters, a Cursor local plugin, offline protocol smoke, and
compare-before-write config merges.

## Install

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Install-HermesObsidianMemory.ps1 `
  -ProjectRoot D:\Projects `
  -InstallObsidian `
  -OpenObsidian
```

Use `-SkipCursor` or `-SkipVSCode` to leave those clients unchanged.
`-PlanOnly` prints derived paths and writes nothing.

The installer pins Hermes Agent `v2026.8.3` (`v0.20.0`) to commit
`3c27eb6234bf91b8ceee9e9071591b31e9b148cb`.

## Components

| Component | Role |
|---|---|
| Hermes native `MEMORY.md` / `USER.md` | Bounded shared agent memory |
| Hermes SQLite / FTS5 | Zero-LLM session recall |
| Obsidian | Human review over the same Hermes home |
| Codex MCP bridge | Exposes native memory and session search to every repo |
| Cursor / VS Code MCP adapters | Merge `hermes-memory` and `hermes-tools` into existing user MCP configs |
| Cursor local plugin | Global worker rule at `plugins/local/ai-os-hermes-worker` |
| Worker instructions | Workers send `memory_candidates` to GPT/Codex; they never write durable memory |
| Project registry | Discovers and registers Git repos without modifying them |

Published as GitHub pre-release
[`v1.6.0-alpha.2`](https://github.com/numtip/ai-operating-system/releases/tag/v1.6.0-alpha.2)
on merge commit `cc3363a`. Live installer re-run remains deferred.

See [RELEASE_NOTES.md](RELEASE_NOTES.md) and
[RELEASE_READINESS.md](RELEASE_READINESS.md).
