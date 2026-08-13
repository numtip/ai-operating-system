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
| **v1.6** | Live Hermes + Obsidian Shared Memory | In Progress | Hermes native bounded memory, FTS5 recall, skills and 28-project registry active; Obsidian views the same home; global launcher + Codex MCP memory bridge verified 2026-08-14. Stage 2 cost observability and production gates remain. |
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
- [x] Human approval obtained for local Hermes installation and shared-memory rollout (2026-08-14).
- [x] GOFFICE2026 pilot Stage 0 (read-only) executed — PASS_WITH_NOTES (evidence: `06_Research/pilots/v1.6-hermes/goffice2026/`)
- [x] Stage 0 blockers remediated (2026-08-09): canonical path `F:\projectAi\goffice2026` established; adapter tip refreshed `7b44c5d`; compiler budget two-tier `preferred 6 / hard 8` (tests 53/53)
- [x] Stage 1 stub compatibility spike executed — 13/13 PASS (SIMULATED; contract surface validated; evidence `STAGE-1-*`)
- [x] Local integration readiness validation (2026-08-09) — goffice2026 PASS; readiness 2.5/5 CONDITIONAL
- [x] Hermes product pin (ADR-0014, 2026-08-09) — hermes-agent v2026.8.3 @ `3c27eb62…`; preflight READY_FOR_LIMITED_LOCAL_INSTALL (conditional)
- [x] Local install + smoke (2026-08-09) — Hermes v0.20.0 sandbox SHA-verified, Obsidian 1.13.4 + AI-OS vault; rollback proven; **real task execution BLOCKED** (model API key required, forbidden) → LOCAL_PILOT_PARTIAL
- [x] **Real DeepSeek pilot (Gate C, 2026-08-09) — LOCAL_RUNTIME_PASS:** GOFFICE2026 read-only audit ×2 through Hermes→DeepSeek `deepseek-v4-flash`; ~$0.01/run estimated; guardrails + rollback proven; evidence `LOCAL_RUNTIME_REPORT.md`
- [x] **GOFFICE2026 FULL READ-ONLY AUDIT (2026-08-09) — FULL_AUDIT_PASS:** 9 sections, PASS_WITH_NOTES (0 CRIT/0 HIGH); no GOFFICE2026 changes; evidence `GOFFICE2026_FULL_READONLY_AUDIT_2026-08-09.md`
- [x] **DOCUMENT CENTER FULL READ-ONLY AUDIT (2026-08-09) — FAIL (CRIT 2/HIGH 2):** auth-URL leak 124/124 in public registry, invalid checksum, reconciliation missing; baseline 627/124/503 confirmed; decision REUSE_EXISTING_SITE_WITH_CONDITIONS; no DC changes; evidence `DOCUMENT_CENTER_FULL_READONLY_AUDIT_2026-08-09.md`
- [x] **Hermes + Obsidian live memory rollout (2026-08-14):** native memory enabled; 28 repositories registered recursively; global `hermes` launcher installed; `hermes_memory` and `hermes_session_search` exposed to Codex through a protocol-tested MCP bridge; Hermes home opened as Obsidian vault.
- [x] **Portable v1.6.0-alpha.1 installer:** immutable version lock, dynamic user/project paths, config backups, Codex managed block, CI plan tests and live end-to-end validation on Windows.
- [ ] Owner decision: reconcile GOFFICE2026 README staleness + evidence files (16/24) + FY2569 data/targets (owner-side, GOFFICE2026 repo); Document Center public-export remediation (owner-side, 5 conditions)
- [x] Human approval obtained for the local installation and all-repo memory rollout; VPS/production remains separately gated.

## Rules

- Use mature native Hermes + Obsidian capabilities before writing integration glue; build only thin bridges for a proven missing client surface.
- Ship docs/specs before runtimes.
- Human approval for push to protected/release branches, deploy, secrets, DNS, and Hermes install.
- Link ADRs for architecture changes; do not rewrite history.
- Existing mature platforms keep their natural ownership boundary unless evidence justifies replacement.

## Related

- [AI_OS_MANIFESTO.md](../AI_OS_MANIFESTO.md)
- [AI_OPERATING_SYSTEM_BLUEPRINT_V4.1_VALIDATED_OPERATING_BASELINE.md](../AI_OPERATING_SYSTEM_BLUEPRINT_V4.1_VALIDATED_OPERATING_BASELINE.md)
- [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)
- [AI_OPERATING_SYSTEM_BLUEPRINT_V4.md](AI_OPERATING_SYSTEM_BLUEPRINT_V4.md)
- [AI_OS_V4_ARCHITECTURE_REVIEW.md](AI_OS_V4_ARCHITECTURE_REVIEW.md)
- [HERMES_ADAPTER_CONTRACT.md](HERMES_ADAPTER_CONTRACT.md)
- [HERMES_ROLLBACK_PLAN.md](HERMES_ROLLBACK_PLAN.md)
- [GOFFICE2026_PILOT_DESIGN.md](GOFFICE2026_PILOT_DESIGN.md)
- [ADR-0013](../04_ADR/ADR-0013-integration-first-hermes-runtime.md)
- [04_ADR/](../04_ADR/)
