# Hermes Capability Matrix

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Purpose:** Classify overlap between Hermes (intended orchestration runtime per ADR-0013 / Blueprint V4 §6-§7) and existing AI-OS v1.0-v1.5 capabilities.
**Rule applied:** No `SUPERSEDE` without concrete evidence (Blueprint V4 §14, §21.6).

## Classification legend

- **RETAIN** — AI-OS remains authoritative; Hermes does not take over this capability.
- **ADAPT** — Connect existing AI-OS capability to Hermes via the adapter contract.
- **SUPERSEDE** — Replace an AI-OS implementation (requires concrete evidence; none in this review).
- **DEFER** — Not required for the current v1.6 pilot.

## Matrix

| Capability | AI-OS v1.0-v1.5 today | Hermes intent (v4/ADR-0013) | Class | Evidence |
|---|---|---|---|---|
| Context | Context Engine (v1.1, ADR-0005), mandatory-context bootstrap | Runtime execution context | RETAIN | v4 §5/§7: context selection/optimization is AI-OS Control Plane authority |
| Memory | Project/Org/Knowledge memory; file-based indexes (v1.0-v1.2) | Runtime state only | RETAIN | v4 §9: knowledge is a first-class AI-OS asset; runtime memory is execution convenience, must not replace canonical knowledge |
| Bootstrap | Bootstrap manifest + readiness gate + CI (v1.5, ADR-0012) | Consumes bootstrap output at execution start | RETAIN | v4 §5/§7: Bootstrap Gate is AI-OS; ADR-0012 unchanged |
| Prompt compilation | Prompt Compiler runtime, no LLM (v1.3, ADR-0011) | Receives compiled execution context | RETAIN | ADR-0011; v4 §5: runtime-neutral contract |
| Quality gate | Prompt Quality Gate (v1.4, alpha) | Pre/post execution validation signals | RETAIN | v4 §7: quality validation is AI-OS pre-execution gate |
| Agents | Agent roles defined (Head + specialists) in specs | Agent manager / coordination | ADAPT | v4 §6/§8: Hermes coordinates agents; AI-OS defines roles, not permanent model assignments |
| Orchestration | None (deferred in v1.0-v1.5) | Preferred orchestration runtime | ADAPT | ADR-0013: Hermes preferred runtime via adapter, replaceable; new capability wired through the adapter |
| Scheduler | None | Hermes / n8n by workflow type | ADAPT | v4 §7: select by workflow characteristics; avoid duplicate automation logic |
| Governance policy | ADR/SOP/policy layer (ADR governance) | Must not become Hermes-authoritative | RETAIN | v4 §6: Hermes not authoritative for governance policy, ADR history, or source-of-truth repos |
| Tool routing | Manual / PowerShell scripts | Tool invocation during execution | ADAPT | v4 §6: Hermes invokes tools within AI-OS policy constraints |
| Model routing | Model profiles (v1.3); policy-based routing spec | Executes the route selected by policy | RETAIN | v4 §8: routing policy is AI-OS; models remain interchangeable |
| Approvals | Human approval policy; impact levels L0-L4 (v4 §11) | Execution-plane approval signals | RETAIN | v4 §11: governance enforced independently of model/runtime |
| Audit | ADR traceability, session logs, decision memory | Execution evidence | ADAPT | v4 §12: audit fields recorded across both planes; adapter maps Hermes evidence to AI-OS audit records |
| Knowledge persistence | Versioned knowledge, Git source of truth (ADR-0002/0003) | Ephemeral runtime state | RETAIN | v4 §9: versioned knowledge independent of execution runtime |
| n8n boundary | n8n deterministic integration workflows | Agentic workflows | ADAPT | v4 §7/§10: Hermes/n8n split by workflow characteristics; no duplicate automation logic |
| M365 / GitHub connectors | GitHub SoT; M365 as enterprise documents | Tool/connector invocation | ADAPT | v4 §10: identity/auth/permission boundaries remain AI-OS + enterprise |
| Observability | Gate metrics, session records (v1.4-v1.5) | Runtime health signals | ADAPT | v4 §13: observability spans Control + Execution planes |
| Semantic / vector memory | None (explicitly deferred) | n/a | DEFER | v4 §9: add only when measurable value beyond deterministic indexes |
| Deployment | Approval-gated DevOps (L3/L4, v4 §7) | Outside spike scope | DEFER | ADR-0013: deployment remains human-approved; not required for design-only pilot |
| Infrastructure | Docker / Ubuntu / Cloudflare (planning only) | No install in this phase | DEFER | ADR-0013: no install without approval; not exercised by the spike |

## Summary counts

| Class | Count |
|-------|-------|
| RETAIN | 9 |
| ADAPT | 8 |
| SUPERSEDE | 0 |
| DEFER | 3 |

## Notes

- `SUPERSEDE` = 0 because no concrete evidence exists (no Hermes install, no runtime comparison).
- Any future `SUPERSEDE` proposal requires a validated compatibility spike + ADR before implementation removal (v4 §14, §21.3).
- All `ADAPT` items pass through the governed task contract defined in `HERMES_ADAPTER_CONTRACT.md`.
