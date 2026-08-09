# Architecture Overview

AI-OS v1 separates cognition (knowledge/memory) from execution. Governance is owned by the AI-OS Control Plane; execution is delegated through a replaceable runtime adapter (integration-first, v1.6).

```text
Human
  ↓ goals / approval
Agents (Head + specialists)
  ↓ read / write
Knowledge  ← Obsidian UI + GitHub SoT
  ↓ governed task contract (v1.6)
Execution  ← Hermes runtime adapter [integration-first; install approval-gated]
```

## Layers

| Layer | Role | Status |
|-------|------|--------|
| Human | Goals, approvals, prod gates | Active |
| Agents | Plan, edit vault, validate | Active |
| Knowledge | Obsidian notes + Git history | Active |
| Control Plane | Context, bootstrap, quality gates, governance | Active (v1.0-v1.5) |
| Execution | Hermes runtime via adapter contract | In progress (v1.6 design-only) |

## Phase boundary

- **v1.0:** local-first vault, memory, ADRs, templates
- **v1.1:** Context Engine, bootstrap SOP, indexes, prompt-compiler spec, compression
- **v1.5:** Agent bootstrap automation + CI gate
- **v1.6 (current):** Integration-first Hermes runtime — adapter contract + capability spike; no install without approval ([ADR-0013](../04_ADR/ADR-0013-integration-first-hermes-runtime.md), [Blueprint V4](AI_OPERATING_SYSTEM_BLUEPRINT_V4.md))

## Decision records

Canonical ADRs live in [../04_ADR/](../04_ADR/).

## Related

- [AI_OPERATING_SYSTEM_BLUEPRINT_V4.md](AI_OPERATING_SYSTEM_BLUEPRINT_V4.md)
- [AI_OS_V4_ARCHITECTURE_REVIEW.md](AI_OS_V4_ARCHITECTURE_REVIEW.md)
- [CONTEXT_ENGINE.md](CONTEXT_ENGINE.md)
- [prompt-compiler/README.md](prompt-compiler/README.md)
- [ROADMAP.md](ROADMAP.md)
- [../AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
- [../04_ADR/ADR-0013-integration-first-hermes-runtime.md](../04_ADR/ADR-0013-integration-first-hermes-runtime.md)
- [../07_Memory/SYSTEM_MEMORY.md](../07_Memory/SYSTEM_MEMORY.md)
