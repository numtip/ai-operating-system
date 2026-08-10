# AI Operating System Blueprint v4.0

## Integration-First Enterprise Architecture

**Status:** Architecture Baseline — Accepted for v1.6
**Accepted:** 2026-08-09
**Date:** 2026-08-09
**Repository:** `numtip/ai-operating-system`
**Target:** AI-OS v1.6+
**Architecture direction:** Integration-first, vendor-neutral, governed digital workforce

> **Mission**
>
> Evolve AI-OS from a knowledge and context foundation into a governed enterprise AI operating layer by integrating proven orchestration, model, knowledge, enterprise, automation, and infrastructure capabilities rather than rebuilding them inside one monolithic runtime.

---

# 1. Executive Vision

AI-OS is **not a chatbot, a single AI model, or an orchestrator**.

AI-OS is a governed operating layer that coordinates:

- Humans and approvals
- AI interfaces
- Context and memory
- Knowledge
- AI models
- Agents
- Orchestration runtimes
- Enterprise systems
- Automation
- Infrastructure
- Audit and learning

The architecture must remain useful even when individual models, tools, orchestrators, or vendors are replaced.

The v4.0 architecture therefore separates the **AI-OS Control Plane** from the **Orchestration / Execution Plane**.

Hermes is treated as an orchestration runtime component of AI-OS, not as AI-OS itself.

---

# 2. Evolution from Earlier Blueprints

AI-OS v4.0 preserves the durable principles established in earlier versions while changing implementation ownership.

## Retained

- Knowledge before Prompt
- Memory before large prompts
- Tool before unnecessary reasoning
- Human-in-the-loop for high-impact operations
- Model-agnostic architecture
- Persistent knowledge
- ADR-based decision traceability
- Git-based version control
- Continuous learning
- Enterprise security and auditability

## Reframed

| Earlier framing | v4.0 framing |
|---|---|
| Hermes as central AI-OS runtime | Hermes as replaceable orchestration/execution runtime |
| Model assigned directly by work type | Policy-based model routing |
| Runtime-owned memory | AI-OS governed knowledge/memory with runtime adapters |
| Build capabilities inside AI-OS | Reuse/integrate mature capabilities first |
| One execution path | Replaceable adapters and execution providers |

Earlier Blueprint and Framework documents remain historical and architectural references. v4.0 does not rewrite their history.

---

# 3. Architecture Principles

1. **Knowledge Before Prompt** — Retrieve authoritative context before constructing prompts.
2. **Architecture Before Implementation** — Define ownership, boundaries, contracts, and gates before runtime installation.
3. **Integration Before Reinvention** — Prefer mature external capabilities over rebuilding equivalent subsystems.
4. **Capability Reuse Before Build** — New code requires a demonstrated capability gap.
5. **Control Plane / Execution Plane Separation** — Governance must not depend on one orchestrator.
6. **Model Agnostic** — Models are interchangeable intelligence providers.
7. **Runtime Replaceable** — Hermes or another orchestrator may be replaced without losing organizational knowledge or governance.
8. **Human Accountability** — AI may plan and execute within policy; humans retain authority for critical decisions.
9. **Everything Important is Traceable** — Architecture decisions, releases, approvals, and learning are versioned.
10. **Least Privilege by Default** — Read and analysis are easier to authorize than external mutation or production deployment.
11. **Evidence Before Completion** — Agents must validate results before declaring work complete.
12. **Continuous Learning** — Validated outcomes improve project memory, SOPs, skills, and future execution.

---

# 4. Reference Architecture v4.0

```text
                    HUMAN / PROJECT OWNER
                            │
                     Goals / Approval
                            │
                            ▼
┌───────────────────────────────────────────────────────┐
│                 AI EXPERIENCE LAYER                   │
│ ChatGPT │ Web │ Telegram │ IDE │ Future Interfaces   │
└───────────────────────────┬───────────────────────────┘
                            │
                            ▼
╔═══════════════════════════════════════════════════════╗
║                 AI-OS CONTROL PLANE                  ║
║                                                       ║
║ Context Engine          │ Knowledge / Memory Policy   ║
║ Bootstrap Gate          │ Prompt Compiler             ║
║ Context Optimizer       │ Prompt Quality Gate         ║
║ Model Routing Policy    │ Security / Approval Policy  ║
║ ADR / Governance        │ Project Adapter             ║
╚══════════════════════════╤════════════════════════════╝
                           │ governed task contract
                           ▼
┌───────────────────────────────────────────────────────┐
│           ORCHESTRATION / EXECUTION PLANE             │
│                                                       │
│                 Hermes Runtime                        │
│ Agent Manager │ Workflow │ Scheduler │ Tool Router    │
│ Task Execution │ Runtime State │ Execution Adapters   │
└───────────────────────────┬───────────────────────────┘
                            │
             ┌──────────────┼──────────────┐
             ▼              ▼              ▼
          AGENTS          MODELS          TOOLS
       Research         Cloud AI        GitHub
       Engineering      Local AI        M365
       Review           Future AI       APIs
       Security                         n8n
       DevOps                           Filesystem
             │              │              │
             └──────────────┼──────────────┘
                            ▼
┌───────────────────────────────────────────────────────┐
│              KNOWLEDGE / DATA PLANE                   │
│ Obsidian │ GitHub │ SharePoint │ Databases │ ADR/SOP │
└───────────────────────────┬───────────────────────────┘
                            ▼
┌───────────────────────────────────────────────────────┐
│                INFRASTRUCTURE PLANE                   │
│ Docker │ Ubuntu VPS │ Cloudflare │ Monitoring        │
└───────────────────────────────────────────────────────┘
```

---

# 5. AI-OS Control Plane

The Control Plane is the durable core of AI-OS.

Its purpose is to decide **how work is prepared, governed, constrained, validated, and learned from** before and after an execution runtime performs the task.

## Current foundation

AI-OS v1.0-v1.5 already establishes major Control Plane capabilities:

- Knowledge foundation
- Project memory
- ADRs
- Context Engine
- Project Adapter
- Prompt Compiler Runtime
- Context Optimizer
- Prompt Quality Gate
- Agent Bootstrap Automation
- Bootstrap CI Gate

These capabilities should be retained unless an integration spike proves that another component provides a superior capability without weakening governance or portability.

## Control Plane responsibilities

- Resolve project identity and policy
- Retrieve mandatory knowledge
- Rank and budget context
- Compile execution context
- Enforce bootstrap readiness
- Select or constrain model/runtime choices
- Determine approval requirements
- Validate task output
- Capture audit evidence
- Promote validated learning back into knowledge

The Control Plane should not become a second workflow engine.

---

# 6. Hermes Runtime Architecture

Hermes is the preferred orchestration candidate for AI-OS v1.6.

Its intended responsibilities are:

- Task orchestration
- Agent coordination
- Workflow execution
- Scheduling
- Tool invocation
- Runtime state
- Execution retries where appropriate
- Adapter invocation

Hermes must **not automatically become authoritative** for:

- Organizational knowledge
- Long-term project memory
- ADR history
- Governance policy
- Production approval
- Source-of-truth repositories

Integration must occur through explicit contracts and adapters.

```text
AI-OS Control Plane
        │
        │ Governed Task Contract
        ▼
   Hermes Adapter
        │
        ▼
      Hermes
        │
        ▼
Agents / Tools / Models
```

If Hermes is replaced in the future, the Control Plane and Knowledge Plane should continue operating with a new runtime adapter.

---

# 7. Capability Ownership Matrix

| Capability | Primary Owner | Notes |
|---|---|---|
| Project context selection | AI-OS | Control Plane authority |
| Mandatory context enforcement | AI-OS | Bootstrap Gate |
| Context optimization | AI-OS | Deterministic where possible |
| Prompt/context compilation | AI-OS | Runtime-neutral contract |
| Prompt quality validation | AI-OS | Pre-execution gate |
| Governance policy | AI-OS | ADR/SOP/policy |
| Human approval policy | AI-OS + Human | Human retains final authority |
| Workflow orchestration | Hermes | Execution Plane |
| Agent coordination | Hermes | Execution Plane |
| Scheduling | Hermes / n8n | Select by workflow characteristics |
| Model inference | Model providers | Replaceable providers |
| Model selection | AI-OS routing policy | Runtime may execute selected route |
| Knowledge authoring UI | Obsidian | Human-friendly knowledge interface |
| Code / architecture source of truth | GitHub | Versioned and auditable |
| Enterprise documents | Microsoft 365 / SharePoint | Enterprise system of record where applicable |
| Business/process automation | n8n / Hermes | Avoid duplicate automation logic |
| Deployment | DevOps tools | Approval gated |
| Infrastructure | Docker / Ubuntu / Cloudflare | Runtime hosting and network |
| Observability | AI-OS + platform tools | Logs, metrics, cost, audit |

---

# 8. Model and Agent Architecture

AI-OS v4.0 does not permanently bind a work category to a named model.

Model selection is policy driven.

```text
Task
  ↓
Capability Requirements
  ↓
Routing Policy
  ↓
Candidate Models
  ↓
Quality / Cost / Privacy / Latency / Availability
  ↓
Selected Provider + Model
```

## Routing factors

- Task complexity
- Required reasoning depth
- Coding capability
- Context-window requirements
- Tool-use capability
- Privacy classification
- Local vs cloud requirement
- Cost budget
- Latency requirement
- Provider availability
- Historical quality evidence

## Agent model

```text
Head / Executive Agent
        │
Coordinator / Orchestrator
        │
├── Research Agent
├── Engineering Agent
├── Review Agent
├── Security Agent
├── Documentation Agent
├── Data Agent
├── DevOps Agent
└── Enterprise Integration Agent
        │
Independent Quality / Policy Gates
```

Agent roles describe responsibilities, not permanent model assignments.

---

# 9. Knowledge and Memory Architecture

Knowledge remains a first-class AI-OS asset independent of the execution runtime.

## Memory layers

### Working Memory
Current execution/session state.

### Project Memory
Project facts, constraints, decisions, operational state, and handoffs.

### Organization Memory
Policies, standards, SOPs, governance, reusable conventions.

### Knowledge Memory
Validated durable knowledge stored in versioned repositories.

### Archive Memory
Historical decisions and superseded operational knowledge retained for traceability.

### Future Semantic Memory
Vector/semantic retrieval may be added only when it provides measurable value beyond deterministic indexes and file-based retrieval.

## Knowledge lifecycle

```text
Retrieve
   ↓
Compile
   ↓
Execute
   ↓
Validate
   ↓
Capture
   ↓
Review / Promote
   ↓
Versioned Knowledge
   ↓
Reuse
```

Runtime memory may be used for execution convenience but must not silently replace canonical knowledge.

---

# 10. Enterprise Integration Architecture

Enterprise systems are connected through adapters/connectors rather than embedding vendor-specific logic throughout the Control Plane.

```text
                    AI-OS
                      │
               Integration Contracts
                      │
      ┌───────────────┼────────────────┐
      ▼               ▼                ▼
   GitHub         Microsoft 365      Databases
                    / SharePoint     SQL/Postgres
      │               │                │
      └───────────────┼────────────────┘
                      ▼
                  APIs / n8n
                      │
                      ▼
             Enterprise Workflows
```

## Initial integration domains

- GitHub
- Microsoft 365
- SharePoint
- PostgreSQL / SQL Server where required
- Cloudflare
- n8n
- External APIs
- Local filesystem / project workspaces

Each integration should define:

- Authentication method
- Permissions
- Read/write scope
- Data classification
- Audit behavior
- Failure behavior
- Human approval boundary

---

# 11. Governance and Human Approval

AI-OS v4.0 uses impact-based execution levels.

| Level | Operation | Default |
|---|---|---|
| **L0** | Read / retrieve | Automatic within granted access |
| **L1** | Analyze / plan / recommend | Automatic |
| **L2** | Non-critical reversible write | Policy controlled |
| **L3** | External mutation / publish / deploy | Human approval required by default |
| **L4** | Security, secrets, destructive or high-impact production action | Explicit owner approval + audit evidence |

Examples of L3/L4 include production deployment, DNS/network changes, secret mutation, destructive database operations, access-control changes, and other actions with significant external impact.

Governance policy must be enforced independently of model confidence.

---

# 12. Security Architecture

## Identity

- OAuth2 / OIDC where supported
- Microsoft Entra ID for enterprise identity where appropriate
- Service identities for automation

## Authorization

- RBAC / least privilege
- Scoped tokens
- Project-specific execution boundaries

## Secrets

- No secrets in prompts, Git history, ADRs, or knowledge notes
- Use environment variables or approved secret-management systems
- Runtime adapters receive only necessary credentials

## Network

- Cloudflare / Zero Trust where appropriate
- Minimize directly exposed runtime services

## Audit

Record where appropriate:

- Actor
- Task
- Context version
- Runtime
- Model/provider
- Tools used
- Approval
- Result
- Validation
- Knowledge updates

---

# 13. Observability

AI-OS observability must span both Control and Execution planes.

Minimum target signals:

- Task success/failure
- Runtime latency
- Model usage
- Token/cost usage where available
- Context size and compression
- Bootstrap gate results
- Prompt quality gate results
- Tool execution failures
- Human approval events
- Deployment events
- Knowledge promotion events

Future dashboards should distinguish **AI quality**, **runtime health**, **cost**, and **business outcome** rather than treating model usage as success.

---

# 14. Integration-First Decision Framework

Before building a new subsystem, classify the required capability.

```text
Required Capability
       ↓
Does an approved component already provide it?
       │
   ┌───┴───┐
  YES      NO
   │        │
Evaluate   Is it strategically
fit       differentiating?
   │        │
   ▼        ▼
RETAIN /   BUILD or
ADAPT /    DEFER
SUPERSEDE
```

For Hermes integration, every overlapping capability should be classified as:

- **RETAIN** — AI-OS remains authoritative.
- **ADAPT** — Connect existing AI-OS capability to Hermes.
- **SUPERSEDE** — Replace an AI-OS implementation only when evidence supports the change.
- **DEFER** — Not required for the current pilot.

No subsystem should be removed merely because Hermes exposes a similarly named feature.

---

# 15. Implementation Roadmap

| Version | Capability | Status |
|---|---|---|
| **v1.0** | Knowledge Foundation | Complete |
| **v1.1** | Context Engine Foundation | Complete |
| **v1.2** | Knowledge Index Maturity / Project Adapter | Complete (RC) |
| **v1.3** | Prompt Compiler Runtime | Complete (MVP) |
| **v1.4** | Context Optimizer + Prompt Quality Gate | Complete (alpha) |
| **v1.5** | Agent Bootstrap Automation + CI Gate | Complete (alpha) |
| **v1.6** | Integration-First Hermes Runtime | Current |
| **v1.7** | Governed Pilot Operations | Planned |
| **v1.8** | Enterprise Connectors | Planned |
| **v1.9** | Observability + Learning Loop Maturity | Planned |
| **v2.0** | Enterprise AI Operating System | Planned |

## v1.6 gates

1. Blueprint v4.0 baseline
2. Hermes capability inventory
3. AI-OS vs Hermes capability matrix
4. RETAIN / ADAPT / SUPERSEDE / DEFER decisions
5. Runtime adapter contract
6. Security and secrets review
7. Pilot execution design
8. Human approval before Hermes installation or production mutation

---

# 16. Reference Pilot — GOFFICE2026

GOFFICE2026 is the preferred first governed pilot because it can exercise project context, GitHub workflows, data operations, validation, deployment gates, and operational learning.

Target pilot flow:

```text
Human Request
      ↓
AI-OS Project Bootstrap
      ↓
Mandatory Project Context
      ↓
Context Optimization / Quality Gate
      ↓
Governed Task Contract
      ↓
Hermes
      ↓
Specialist Agents
      ↓
GitHub / Files / APIs / Tools
      ↓
Independent Validation
      ↓
Human Approval when required
      ↓
Publish / Deploy
      ↓
Operational Evidence
      ↓
Lessons Learned
      ↓
Knowledge Update
```

## Pilot success criteria

Measure evidence, not novelty:

- Correct mandatory-context retrieval
- No unauthorized production mutation
- Reduced manual orchestration effort
- Reduced unnecessary context/token usage
- Reproducible task execution
- Clear audit trail
- Successful quality gates
- Recoverable failure behavior
- Useful knowledge captured after execution

The pilot should demonstrate that Hermes improves execution while AI-OS retains governance and knowledge authority.

---

# 17. Failure and Replacement Strategy

AI-OS must tolerate failure or replacement of individual components.

## If Hermes fails

- Preserve knowledge and project state outside Hermes where practical.
- Stop unsafe execution.
- Record failure evidence.
- Permit manual or alternative-runtime continuation.

## If a model provider fails

- Route to an approved alternative where policy allows.
- Do not silently downgrade privacy or security requirements.

## If an enterprise connector fails

- Fail closed for mutations when state is uncertain.
- Avoid duplicate writes on retry.
- Preserve idempotency where possible.

## If AI output fails validation

- Do not promote it to canonical knowledge.
- Retry, escalate, or return to human review according to policy.

---

# 18. Project Standard

Each governed AI-OS project should expose or map to the following logical artifacts:

```text
Architecture/
Blueprint/
ADR/
Knowledge/
Meetings/
Research/
Tasks/
Automation/
Release/
Reports/
Lessons-Learned/
```

Physical folder structure may vary by repository, but the Project Adapter must make required artifacts discoverable.

---

# 19. Definition of AI-OS v2.0

AI-OS reaches the Enterprise AI Operating System milestone when it can demonstrably:

- Govern multiple projects
- Bootstrap agents deterministically
- Retrieve authoritative project context
- Route models by policy
- Orchestrate multi-agent execution through replaceable runtimes
- Integrate enterprise systems through governed connectors
- Enforce human approval boundaries
- Produce auditable execution evidence
- Observe quality, cost, runtime health, and outcomes
- Capture validated learning into persistent knowledge
- Replace models or orchestration components without losing organizational memory

---

# 20. Vision 2030

The target is a governed enterprise digital operating layer.

Humans provide:

- Vision
- Ethics
- Accountability
- Priority
- Exception handling
- Final authority for critical operations

AI-OS provides:

- Context
- Planning
- Research
- Engineering
- Coordination
- Validation
- Automation
- Monitoring
- Knowledge management
- Continuous improvement

The architecture should allow the organization to evolve from isolated AI tools into a coordinated digital workforce **without surrendering knowledge, governance, or operational control to any single AI vendor or runtime**.

---

# 21. Architecture Baseline Rules

1. This document is the accepted v4.0 implementation architecture baseline for AI-OS v1.6 (accepted 2026-08-09; see `AI_OS_V4_ARCHITECTURE_REVIEW.md`).
2. Historical Blueprints and ADRs are not rewritten to simulate agreement with v4.0.
3. Architecture changes require a new ADR or an explicitly versioned superseding decision.
4. Hermes installation is not implied by this document; installation remains approval-gated.
5. Production mutation remains human approval-gated.
6. Capability overlap must be evaluated before implementation removal.
7. GitHub remains the versioned source of truth for AI-OS architecture artifacts.

---

# 22. Related Records

- `AI_OS_MANIFESTO.md`
- `03_Architecture/ARCHITECTURE_OVERVIEW.md`
- `03_Architecture/ROADMAP.md`
- `04_ADR/ADR-0004-hermes-deferred-phase-2.md`
- `04_ADR/ADR-0013-integration-first-hermes-runtime.md`
- `07_Memory/SYSTEM_MEMORY.md`

---

## Final Architecture Statement

> **AI-OS governs. Hermes orchestrates. Models reason. Agents specialize. Tools execute. Knowledge persists. Humans remain accountable.**
