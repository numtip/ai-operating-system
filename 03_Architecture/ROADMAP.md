# Roadmap

Versioned capability path for AI Operating System. Do not mark future items complete.

| Version | Name | Status | Focus |
|---------|------|--------|--------|
| **v1.0** | Knowledge Foundation | Complete | Obsidian + Git + Memory + ADRs + templates |
| **v1.1** | Context Engine Foundation | Complete | Context chain, bootstrap protocol, indexes, prompt compiler spec, compression, manifesto |
| **v1.2** | Knowledge Index Maturity | Complete (RC) | Project Adapter, bootstrap runtime sim, context metrics, goffice2026 pilot |
| **v1.3** | Prompt Compiler Runtime | Complete (MVP) | Compile prompts from specs; no LLM; model profiles + pilots |
| **v1.4** | Context Optimizer + Prompt Quality Gate | Complete (alpha) | Deterministic context ranking/budget, duplicate/low-value elimination, mandatory-context preservation, pre-execution prompt quality gate, structured metrics |
| **v1.5** | Agent Bootstrap Automation | Complete (alpha) | Enforce bootstrap manifest + readiness gates in tooling + CI |
| **v1.6** | Integration-First Hermes Runtime | In Progress | Hermes adapter contract + reversible compatibility spike; retain AI-OS governance gates; no install/deploy without approval (ADR-0013) |
| **v1.7** | Governed Pilot Operations | Planned | One low-risk project through Hermes + bootstrap/context/quality gates; measure success, latency, cost, auditability, operator effort |
| **v2.0** | Enterprise AI Operating System | Planned | Multi-project operations across GitHub, Obsidian, M365, n8n, Docker/VPS/Cloudflare with explicit ownership and approval gates |

## v1.6 Exit Criteria

- Hermes capability/compatibility matrix completed.
- Adapter contract defined before runtime installation.
- Existing v1.0-v1.5 capabilities classified as RETAIN / ADAPT / SUPERSEDE / DEFER.
- Local-first rollback plan documented.
- No secrets, production, DNS, or VPS mutation required for the architecture spike.
- Human approval obtained before any Hermes installation.

## Rules

- Integrate before building replacement infrastructure.
- Ship docs/specs before runtimes.
- Human approval for push to protected/release branches, deploy, secrets, DNS, and Hermes install.
- Link ADRs for architecture changes; do not rewrite history.
- Existing mature platforms keep their natural ownership boundary unless evidence justifies replacement.

## Related

- [AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
- [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)
- [ADR-0013](../04_ADR/ADR-0013-integration-first-hermes-runtime.md)
- [04_ADR/](../04_ADR/)
