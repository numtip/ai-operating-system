# AI Operating System

Local-first knowledge, memory, and context foundation for human + agent work.

**Repo:** https://github.com/numtip/ai-operating-system  
**Track:** v1.3 — Prompt Compiler Runtime (MVP)  
**Manifesto:** [AI_OS_MANIFESTO.md](AI_OS_MANIFESTO.md)  
**Release (prior RC):** [10_Releases/v1.2.0-rc.1/](10_Releases/v1.2.0-rc.1/)

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

- No Hermes install or orchestration runtime (until v1.5 / approval)
- No VPS / production deploy without approval
- No secrets in the vault; no vector DB in v1.1
- Prompt Compiler runtime is local/file-based (no model API calls)

## Agent bootstrap

Mandatory: [09_SOP/AGENT_BOOTSTRAP.md](09_SOP/AGENT_BOOTSTRAP.md)  
Quick entry: [00_Dashboard/QUICKSTART.md](00_Dashboard/QUICKSTART.md)
