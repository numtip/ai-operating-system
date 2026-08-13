# v1.6.0-alpha.1

Hermes + Obsidian shared-memory integration for Windows.

## Install

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Install-HermesObsidianMemory.ps1 `
  -ProjectRoot D:\Projects `
  -InstallObsidian `
  -OpenObsidian
```

The installer is path-portable and derives user locations at runtime. It pins
Hermes Agent `v2026.8.3` (`v0.20.0`) to commit
`3c27eb6234bf91b8ceee9e9071591b31e9b148cb`.

## Components

| Component | Role |
|---|---|
| Hermes native `MEMORY.md` / `USER.md` | Bounded shared agent memory |
| Hermes SQLite / FTS5 | Zero-LLM session recall |
| Obsidian | Human review over the same Hermes home |
| Codex MCP bridge | Exposes native memory and session search to every repo |
| Global AGENTS workflow | Requires memory-first behavior without duplicating storage |
| Project registry | Discovers and registers Git repos without modifying them |

See [RELEASE_NOTES.md](RELEASE_NOTES.md) and
[RELEASE_READINESS.md](RELEASE_READINESS.md).
