# System Memory

Durable facts for AI Operating System. Update only when the system itself changes.

## Identity

| Fact | Value |
|------|--------|
| Repo path | `F:\projectAi\ai-operating-system` |
| GitHub | https://github.com/numtip/ai-operating-system |
| Product | AI Operating System |
| Current version track | v1.1 Context Engine Foundation |

## Phase / version model

| Version | Status | Scope |
|---------|--------|--------|
| **v1.0** | Complete | Knowledge/Memory foundation (Obsidian + Git) |
| **v1.1** | Active | Context Engine, bootstrap, indexes, prompt-compiler spec, compression |
| **v1.5 / Phase 2** | Deferred | Hermes agent runtime (not installed) |

See [ROADMAP](../03_Architecture/ROADMAP.md).

## Constraints (current)

- Local-first; Obsidian as primary interface
- Git / GitHub as source of truth
- File-based indexes (no vector DB yet)
- Prompt Compiler is specification-only (no API calls)
- No VPS; no Hermes install until approved
- Session compression threshold default: 25

## Related

- Status: [CURRENT_STATE](CURRENT_STATE.md)
- Decisions: [DECISION_MEMORY](DECISION_MEMORY.md)
- Rules: [OPERATING_RULES](OPERATING_RULES.md)
- Manifesto: [AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
