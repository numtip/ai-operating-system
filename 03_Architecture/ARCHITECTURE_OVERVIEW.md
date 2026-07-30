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

- **v1.0:** local-first vault, memory, ADRs, templates
- **v1.1:** Context Engine, bootstrap SOP, indexes, prompt-compiler spec, compression
- **Later (v1.5 / Phase 2):** Hermes orchestration — see [ROADMAP.md](ROADMAP.md)

## Decision records

Canonical ADRs live in [../04_ADR/](../04_ADR/).

## Related

- [CONTEXT_ENGINE.md](CONTEXT_ENGINE.md)
- [prompt-compiler/README.md](prompt-compiler/README.md)
- [ROADMAP.md](ROADMAP.md)
- [../AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
- [../07_Memory/SYSTEM_MEMORY.md](../07_Memory/SYSTEM_MEMORY.md)
