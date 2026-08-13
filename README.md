# AI Operating System

Local-first knowledge, memory, and context foundation for human + agent work.

**Repo:** https://github.com/numtip/ai-operating-system  
**Track:** v1.6 — Hermes + Obsidian Shared Memory (alpha)
**Manifesto:** [AI_OS_MANIFESTO.md](AI_OS_MANIFESTO.md)  
**Release:** [10_Releases/v1.6.0-alpha.1/](10_Releases/v1.6.0-alpha.1/)

## Install Hermes + Obsidian shared memory on Windows

The installer pins Hermes Agent `v2026.8.3` (`v0.20.0`) to commit
`3c27eb6234bf91b8ceee9e9071591b31e9b148cb`, enables its native memory and
FTS5 session search, registers repositories, configures the same directory as
an Obsidian vault, and connects Codex through MCP.

```powershell
git clone https://github.com/numtip/ai-operating-system.git
cd ai-operating-system
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Install-HermesObsidianMemory.ps1 `
  -ProjectRoot D:\Projects `
  -InstallObsidian `
  -OpenObsidian
```

Review the computed paths without changing the machine:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Install-HermesObsidianMemory.ps1 `
  -ProjectRoot D:\Projects `
  -PlanOnly
```

Restart Codex once after installation so it loads the global Hermes workflow
and the `hermes_memory` / `hermes_session_search` MCP tools. No credentials or
model-provider keys are installed or copied by this workflow.

## Vault tree

```text
00_Dashboard/     # entry + quickstart
01_Projects/      # active work
02_Knowledge/     # glossary, notes
03_Architecture/  # design, context engine, prompt-compiler, roadmap
04_ADR/           # architecture decisions
05_Meetings/
06_Research/
07_Memory/        # rules, state, sessions, compression
08_Skills/
09_SOP/           # bootstrap + operating procedures
10_Releases/
11_Templates/     # reusable templates (+ context/)
12_Indexes/       # lightweight JSON indexes
prompt-compiler/  # compiler runtime: profiles, schemas, tests (v1.3+)
Archive/
scripts/          # validation helpers
```

## Canonical links

| Topic | Path |
|-------|------|
| Dashboard | [00_Dashboard/HOME.md](00_Dashboard/HOME.md) |
| Agent bootstrap | [09_SOP/AGENT_BOOTSTRAP.md](09_SOP/AGENT_BOOTSTRAP.md) |
| Context Engine | [03_Architecture/CONTEXT_ENGINE.md](03_Architecture/CONTEXT_ENGINE.md) |
| Prompt Compiler (spec) | [03_Architecture/prompt-compiler/](03_Architecture/prompt-compiler/) |
| Prompt Compiler (runtime) | [prompt-compiler/](prompt-compiler/) · `scripts/compile-prompt.ps1` |
| Indexes | [12_Indexes/](12_Indexes/) |
| Roadmap | [03_Architecture/ROADMAP.md](03_Architecture/ROADMAP.md) |
| Operating rules | [07_Memory/OPERATING_RULES.md](07_Memory/OPERATING_RULES.md) |
| Current state | [07_Memory/CURRENT_STATE.md](07_Memory/CURRENT_STATE.md) |
| ADRs | [04_ADR/](04_ADR/) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

## Constraints

- Hermes native memory, FTS5 session search and skills remain the memory backend; AI-OS does not replace them
- Obsidian is the human interface over the same Hermes home
- No VPS / production deploy without approval
- No secrets in the vault; no vector DB
- Prompt Compiler runtime is local/file-based (no model API calls)
- Compiler runtime lives at repo-root `prompt-compiler/`; spec/contracts at `03_Architecture/prompt-compiler/` (ADR-0011)

## Agent bootstrap

Mandatory: [09_SOP/AGENT_BOOTSTRAP.md](09_SOP/AGENT_BOOTSTRAP.md)  
Quick entry: [00_Dashboard/QUICKSTART.md](00_Dashboard/QUICKSTART.md)
