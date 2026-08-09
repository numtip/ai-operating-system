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
| **v1.6** | Integration-First Hermes Runtime | In Progress | Blueprint V4 baseline accepted; adapter contract + capability matrix + rollback plan + GOFFICE2026 pilot design; retain AI-OS governance gates; no install/deploy without approval (ADR-0013) |
| **v1.7** | Governed Pilot Operations | Planned | One low-risk project through Hermes + bootstrap/context/quality gates; measure success, latency, cost, auditability, operator effort |
| **v1.8** | Enterprise Connectors | Planned | Governed connectors: GitHub, Microsoft 365/SharePoint, PostgreSQL/SQL Server, Cloudflare, n8n, external APIs |
| **v1.9** | Observability + Learning Loop Maturity | Planned | AI quality vs runtime health vs cost vs outcome signals; knowledge promotion loop |
| **v2.0** | Enterprise AI Operating System | Planned | Multi-project operations across GitHub, Obsidian, M365, n8n, Docker/VPS/Cloudflare with explicit ownership and approval gates |

## v1.6 Exit Criteria

- [x] Hermes capability/compatibility matrix completed.
- [x] Adapter contract defined before runtime installation.
- [x] Existing v1.0-v1.5 capabilities classified as RETAIN / ADAPT / SUPERSEDE / DEFER.
- [x] Local-first rollback plan documented.
- [x] No secrets, production, DNS, or VPS mutation required for the architecture spike.
- [ ] Human approval obtained before any Hermes installation.
- [ ] GOFFICE2026 pilot design executed through stages (install-gated).

## Rules

- Integrate before building replacement infrastructure.
- Ship docs/specs before runtimes.
- Human approval for push to protected/release branches, deploy, secrets, DNS, and Hermes install.
- Link ADRs for architecture changes; do not rewrite history.
- Existing mature platforms keep their natural ownership boundary unless evidence justifies replacement.

## Related

- [AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
- [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)
- [AI_OPERATING_SYSTEM_BLUEPRINT_V4.md](AI_OPERATING_SYSTEM_BLUEPRINT_V4.md)
- [AI_OS_V4_ARCHITECTURE_REVIEW.md](AI_OS_V4_ARCHITECTURE_REVIEW.md)
- [HERMES_ADAPTER_CONTRACT.md](HERMES_ADAPTER_CONTRACT.md)
- [HERMES_ROLLBACK_PLAN.md](HERMES_ROLLBACK_PLAN.md)
- [GOFFICE2026_PILOT_DESIGN.md](GOFFICE2026_PILOT_DESIGN.md)
- [ADR-0013](../04_ADR/ADR-0013-integration-first-hermes-runtime.md)
- [04_ADR/](../04_ADR/)
