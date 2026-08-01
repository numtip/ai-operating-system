# Roadmap

Versioned capability path for AI Operating System. Do not mark future items complete.

| Version | Name | Status | Focus |
|---------|------|--------|--------|
| **v1.0** | Knowledge Foundation | Complete | Obsidian + Git + Memory + ADRs + templates |
| **v1.1** | Context Engine Foundation | Complete | Context chain, bootstrap protocol, indexes, prompt compiler spec, compression, manifesto |
| **v1.2** | Knowledge Index Maturity | Complete (RC) | Project Adapter, bootstrap runtime sim, context metrics, goffice2026 pilot |
| **v1.3** | Prompt Compiler Runtime | Complete (MVP) | Compile prompts from specs; no LLM; model profiles + pilots |
| **v1.4** | Context Optimizer + Prompt Quality Gate | Complete (alpha) | Deterministic context ranking/budget, duplicate/low-value elimination, mandatory-context preservation, pre-execution prompt quality gate, structured metrics |
| **v1.5** | Agent Bootstrap Automation | In progress (alpha) | Enforce bootstrap manifest + readiness gates in tooling |
| **v1.6** | Hermes Integration | Planned | Orchestrator (see ADR-0004); install only with approval |
| **v2.0** | Enterprise AI Operating System | Planned | Multi-project enterprise ops (M365, deploy gates, etc.) |

## Rules

- Ship docs/specs before runtimes.
- Human approval for push, deploy, secrets, Hermes install.
- Link ADRs for architecture changes; do not rewrite history.

## Related

- [AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
- [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)
- [04_ADR/](../04_ADR/)
