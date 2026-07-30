# AI Operating System v1

Local-first knowledge and memory foundation for human + agent work.

**Repo:** https://github.com/numtip/ai-operating-system  
**Phase:** 1 — Obsidian + Git + Knowledge (execution/Hermes deferred)

## Vault tree

```text
00_Dashboard/     # entry + quickstart
01_Projects/      # active work
02_Knowledge/     # glossary, notes
03_Architecture/  # system design
04_ADR/           # architecture decisions
05_Meetings/
06_Research/
07_Memory/        # operating rules, state, sessions
08_Skills/
09_SOP/
10_Releases/
11_Templates/     # reusable templates
Archive/
scripts/          # validation helpers
```

## Phase 1 scope

- Obsidian as the knowledge interface
- Git/GitHub as source of truth
- Persistent memory, ADRs, templates, session handoffs

## Canonical links

| Topic | Path |
|-------|------|
| Dashboard | [00_Dashboard/HOME.md](00_Dashboard/HOME.md) |
| Agent bootstrap | [00_Dashboard/QUICKSTART.md](00_Dashboard/QUICKSTART.md) |
| Operating rules | [07_Memory/OPERATING_RULES.md](07_Memory/OPERATING_RULES.md) |
| System memory | [07_Memory/SYSTEM_MEMORY.md](07_Memory/SYSTEM_MEMORY.md) |
| Current state | [07_Memory/CURRENT_STATE.md](07_Memory/CURRENT_STATE.md) |
| Sessions | [07_Memory/SESSION_INDEX.md](07_Memory/SESSION_INDEX.md) |
| ADRs | [04_ADR/](04_ADR/) |
| Templates | [11_Templates/](11_Templates/) |
| Architecture | [03_Architecture/ARCHITECTURE_OVERVIEW.md](03_Architecture/ARCHITECTURE_OVERVIEW.md) |
| Glossary | [02_Knowledge/GLOSSARY.md](02_Knowledge/GLOSSARY.md) |

## Constraints (Phase 1)

- No Hermes install or orchestration runtime
- No VPS / production deploy
- No secrets, credentials, or `.env` in the vault
- Do not modify other repositories

## Agent bootstrap

Follow [00_Dashboard/QUICKSTART.md](00_Dashboard/QUICKSTART.md).  
Read memory and summaries before history. One Head Agent owns integration, validation, and commits.
