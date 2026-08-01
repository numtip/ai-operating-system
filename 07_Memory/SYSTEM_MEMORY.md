# System Memory

Durable facts for AI Operating System. Update only when the system itself changes.

## Identity

| Fact | Value |
|------|--------|
| Repo path | `F:\projectAi\ai-operating-system` |
| GitHub | https://github.com/numtip/ai-operating-system |
| Product | AI Operating System |
| Current version track | v1.4 Context Optimizer + Prompt Quality Gate (alpha) |

## Phase / version model

| Version | Status | Scope |
|---------|--------|--------|
| **v1.0** | Complete | Knowledge/Memory foundation |
| **v1.1** | Complete | Context Engine, bootstrap SOP, indexes, prompt-compiler spec, compression |
| **v1.2** | Complete (RC) | Project Adapter + bootstrap runtime sim + metrics; goffice2026 pilot |
| **v1.3** | Complete (MVP) | Prompt Compiler runtime (no LLM); model profiles; dual pilots |
| **v1.4** | Complete (alpha) | Context Optimizer + Prompt Quality Gate; deterministic budget/ranking |
| **v1.5** | Planned | Agent Bootstrap Automation (enforce manifest + readiness gates) |
| **v1.6 / Phase 2** | Deferred | Hermes (not installed) |

See [ROADMAP](../03_Architecture/ROADMAP.md).

## Constraints (current)

- Local-first; Obsidian as primary interface
- Git / GitHub as source of truth
- File-based indexes (no vector DB)
- Project Adapters link external repos; do not duplicate docs
- Prompt Compiler runtime is local/file-based (no model API)
  - Spec/contracts: `03_Architecture/prompt-compiler/`
  - Runtime: repo-root `prompt-compiler/` (ADR-0011)
- No Hermes / VPS without approval
- Session compression threshold default: 25

## First pilot

| Fact | Value |
|------|--------|
| Project | goffice2026 |
| Adapter | `01_Projects/goffice2026/ADAPTER.md` |
| External path | `F:\projectAi\goffice2026` |
| Remote | https://github.com/numtip/goffice2026 |

## Related

- Status: [CURRENT_STATE](CURRENT_STATE.md)
- Decisions: [DECISION_MEMORY](DECISION_MEMORY.md)
- Rules: [OPERATING_RULES](OPERATING_RULES.md)
