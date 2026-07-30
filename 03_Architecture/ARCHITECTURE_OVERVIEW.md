# Architecture Overview

AI-OS v1 separates cognition (knowledge/memory) from execution.

```text
Human
  ↓ goals / approval
Agents (Head + specialists)
  ↓ read / write
Knowledge  ← Obsidian UI + GitHub SoT
  ↓ (Phase 2+)
Execution  ← Hermes / runtime  [deferred]
```

## Layers

| Layer | Role | Phase 1 |
|-------|------|---------|
| Human | Goals, approvals, prod gates | Active |
| Agents | Plan, edit vault, validate | Active |
| Knowledge | Obsidian notes + Git history | Active |
| Execution | Hermes, VPS, automation | Deferred |

## Phase boundary

- **Now:** local-first vault, memory, ADRs, templates
- **Later (Phase 2):** Hermes orchestration, Telegram, remote runtime

## Decision records

Canonical ADRs live in [../04_ADR/](../04_ADR/). Expected Phase 1 decisions:

- Local-first development
- GitHub as source of truth
- Obsidian as knowledge interface
- Hermes deferred to Phase 2

## Related

- [../README.md](../README.md)
- [../07_Memory/SYSTEM_MEMORY.md](../07_Memory/SYSTEM_MEMORY.md)
- [../02_Knowledge/GLOSSARY.md](../02_Knowledge/GLOSSARY.md)
