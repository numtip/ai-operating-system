# Architecture Overview

AI-OS v1 separates cognition (knowledge/memory) from execution. Governance is owned by the AI-OS Control Plane; execution is delegated through a replaceable runtime adapter (integration-first, v1.6).

```text
Human
  ↓ goals / approval
Agents (Head + specialists)
  ↓ native memory / governed work
Memory     ← Hermes MEMORY.md + USER.md + FTS5 sessions
  ↔ review
Obsidian   ← human UI over the same Hermes home
  ↓ canonical artifacts
Knowledge  ← GitHub / approved project systems
Execution  ← Hermes runtime + thin client integrations
```

## Layers

| Layer | Role | Status |
|-------|------|--------|
| Human | Goals, approvals, prod gates | Active |
| Agents | Plan, edit vault, validate | Active |
| Memory | Hermes native bounded memory, skills and FTS5 sessions | Active (v1.6) |
| Knowledge | Obsidian review + Git/project systems | Active |
| Control Plane | Thin policy, bootstrap, quality gates and evidence | Active |
| Execution | Hermes runtime + Codex MCP integration | Active locally (v1.6 alpha) |

## Phase boundary

- **v1.0:** local-first vault, memory, ADRs, templates
- **v1.1:** Context Engine, bootstrap SOP, indexes, prompt-compiler spec, compression
- **v1.5:** Agent bootstrap automation + CI gate
- **v1.6 (current):** live Hermes + Obsidian shared memory with a portable Windows installer and Codex MCP integration; VPS/production remains separately approval-gated ([ADR-0013](../04_ADR/ADR-0013-integration-first-hermes-runtime.md), [Blueprint V4.1](../AI_OPERATING_SYSTEM_BLUEPRINT_V4.1_VALIDATED_OPERATING_BASELINE.md))

## Decision records

Canonical ADRs live in [../04_ADR/](../04_ADR/).

## Related

- [AI_OPERATING_SYSTEM_BLUEPRINT_V4.1_VALIDATED_OPERATING_BASELINE.md](../AI_OPERATING_SYSTEM_BLUEPRINT_V4.1_VALIDATED_OPERATING_BASELINE.md)
- [AI_OPERATING_SYSTEM_BLUEPRINT_V4.md](AI_OPERATING_SYSTEM_BLUEPRINT_V4.md)
- [AI_OS_V4_ARCHITECTURE_REVIEW.md](AI_OS_V4_ARCHITECTURE_REVIEW.md)
- [CONTEXT_ENGINE.md](CONTEXT_ENGINE.md)
- [prompt-compiler/README.md](prompt-compiler/README.md)
- [ROADMAP.md](ROADMAP.md)
- [../AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
- [../04_ADR/ADR-0013-integration-first-hermes-runtime.md](../04_ADR/ADR-0013-integration-first-hermes-runtime.md)
- [../07_Memory/SYSTEM_MEMORY.md](../07_Memory/SYSTEM_MEMORY.md)
