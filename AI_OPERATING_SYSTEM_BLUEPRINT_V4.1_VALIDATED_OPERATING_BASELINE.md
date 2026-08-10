# AI Operating System Blueprint v4.1

## Validated Operating Baseline

**Status:** Superseding operating baseline for AI-OS v1.6+
**Date:** 2026-08-09
**Supersedes:** Operational sections of `AI_OPERATING_SYSTEM_BLUEPRINT_V4.md`
**Keeps:** v4.0 as the integration-first architecture baseline and historical record

> **Architecture statement**
> **AI-OS governs. Obsidian and canonical systems preserve knowledge. Hermes orchestrates bounded execution. Models reason from curated context. Humans authorize material change.**

---

## 1. Why v4.1 exists

v4.0 correctly defined the separation of Control Plane, Execution Plane, and Knowledge/Data Plane. Two governed, read-only pilots now provide operational evidence:

| Pilot | Execution result | Material finding | What it proves |
|---|---|---|---|
| GOFFICE2026 | `FULL_AUDIT_PASS` | FY2569 coverage/evidence gaps | Hermes can perform bounded multi-step audit without mutating the target repository. |
| Document Center | `FULL_AUDIT_PASS` | Public registry had authenticated URLs, invalid checksum and reconciliation defects | A governed audit can find real cross-project control failures; runtime success is distinct from project release readiness. |

This is not a production-readiness declaration. It turns the proven parts into default operating rules and makes the unproven parts explicit gates.

---

## 2. Non-negotiable ownership model

| Plane | Authoritative owner | Purpose | Must not become |
|---|---|---|---|
| Knowledge/Data | Obsidian, Git, SharePoint/M365, approved databases | Durable, reviewable organizational and project memory | A hidden runtime cache or prompt-log archive |
| Control | AI-OS | Context selection, policy, task contracts, validation, evidence and approval routing | A duplicate workflow engine |
| Execution | Hermes | Workflow state, retries, agent/tool coordination and bounded task execution | The owner of long-term memory, policy, source data or production approval |
| Intelligence | Approved model providers | Reasoning within the supplied contract | The authority for risk acceptance or canonical fact storage |
| Accountability | Project owner / authorized human | Approval, exception handling, release decisions | An automated afterthought |

**Rule:** Hermes working state is disposable. Any fact worth retaining must be validated, classified and promoted to a canonical Markdown record, repository, SharePoint location or database through an approved write path.

---

## 3. Validated operating scope

| Capability | Status | Default policy |
|---|---|---|
| Read-only, multi-step, cross-project audit | `VALIDATED` | Allowed at L0/L1 with a project adapter and an evidence destination. |
| Curated-context execution through Hermes + DeepSeek | `VALIDATED` | Allowed only after context and prompt gates pass. |
| Evidence capture in AI-OS integration branch | `VALIDATED` | Evidence-only commits; never mutate the target project. |
| Knowledge promotion to Obsidian/canonical systems | `DESIGNED_NOT_YET_PROVEN` | Human review and write-path test required. |
| Target-project file writes | `NOT_YET_PROVEN` | Human-approved L2 pilot only; separate from read-only mode. |
| Publish, deploy, external-system mutation | `NOT_YET_PROVEN` | L3; human approval and independent validation required. |
| Secrets, destructive or access-control change | `NOT_AUTHORIZED_BY_PILOT` | L4; explicit owner approval plus dedicated procedure. |

`FULL_AUDIT_PASS` means the audit execution and its controls passed. It never means the audited project is safe to publish or deploy.

---

## 4. Standard governed-task lifecycle

```text
Request
  → AI-OS resolves project adapter and risk level
  → retrieves authoritative context
  → applies context budget and prompt quality gate
  → creates governed task contract
  → Hermes executes only the contract
  → independent validation and evidence capture
  → human review where required
  → approved knowledge promotion or close
```

### 4.1 Required task contract

Every Hermes task must state:

1. Project identity, canonical local path, branch and starting commit.
2. Purpose and success criteria.
3. Risk level (L0–L4) and explicit allowed/forbidden actions.
4. Authoritative sources and context-file budget.
5. Provider/model route, privacy class and cost/time guardrails.
6. Validation commands and definition of evidence.
7. Exact destination for evidence; for L2+ the approval record and rollback/recovery procedure.
8. Required final verdict: execution verdict, target/project verdict, and governance recommendation—reported separately.

### 4.2 Read-only invariant

For an L0/L1 audit, capture `HEAD` and `git status --porcelain` before and after. The target passes the non-mutation invariant only when both tracked state and commit are unchanged. Generated, ignored output may exist only if explicitly permitted in the contract.

---

## 5. Context and memory policy

### 5.1 Context is retrieval, not bulk ingestion

- Preferred context set: **≤6 files**.
- Hard maximum: **8 files**. Exceeding it requires a written exception in task evidence.
- Include the adapter, policy/ADR, current state, canonical contract/schema and only task-specific evidence.
- Prefer deterministic indexes, manifests, schemas and summaries before large raw documents.
- Never treat a model’s previous answer or Hermes runtime state as canonical memory.

### 5.2 Promotion gate

An output may enter durable memory only when it has all of the following:

| Gate | Requirement |
|---|---|
| Evidence | Source/command/result is traceable. |
| Validation | Checks appropriate to the claim passed. |
| Ownership | A named canonical destination and owner exist. |
| Classification | Facts, decision, SOP, lesson, or transient observation are distinguished. |
| Review | Human review for policy, architectural or operationally material claims. |
| Versioning | The promoted record is versioned and linked to its evidence. |

Unvalidated output remains task evidence, not memory.

---

## 6. Token, cost and performance governance

The pilots prove viability but do **not** yet prove low-cost default operation. Their runtime-reported total-token field did not reconcile with provider input/output figures, so it must not be used as a billing fact.

### 6.1 Required metric ledger

Every governed Hermes run records these separately:

| Metric | Source of truth | Required |
|---|---|---|
| Provider input tokens | Provider/API response or usage report | Yes |
| Provider output tokens | Provider/API response or usage report | Yes |
| Provider billed cost | Provider billing/usage record where available | Yes |
| Hermes calls, retries and failures | Hermes trace | Yes |
| Runtime-reported aggregate tokens | Hermes trace, labelled non-billing until reconciled | Yes |
| Context file count and byte/token estimate | AI-OS prompt compiler | Yes |
| End-to-end elapsed time | Task trace | Yes |
| Quality outcome and validation result | Independent validator | Yes |

### 6.2 Guardrails

- Use Hermes by default only for tasks that need orchestration, retries, traceability or multiple dependent steps.
- Use a direct agent/model for a short, single-file or simple advisory task unless an exception needs Hermes controls.
- Define a per-run call cap, time cap and cost cap before execution; stop and return `BUDGET_EXCEEDED` rather than silently continuing.
- Compare each recurring workflow with its last approved baseline using quality, elapsed time, provider cost and operator effort.

Pilot reference, not an SLA: GOFFICE audit used 16 calls / about 240 seconds / estimated $0.0151; Document Center used 14 calls / about 197 seconds / estimated $0.0166. These are workload observations, not general unit prices.

---

## 7. Project adapter standard

Every onboarded project requires a current adapter with:

- canonical paths and repository identity;
- systems of record and explicit downstream artifacts;
- read/write authority boundaries;
- public/private data classification and secret-redaction rules;
- required context sources, schema/manifests and validations;
- deployment boundary and rollback owner;
- known exceptions, stale metadata date and adapter-review owner.

Adapter freshness is a governance signal. A stale adapter downgrades the run to `PASS_WITH_NOTES` at most and must create a maintenance action; it must not be silently ignored.

---

## 8. Validation and release gates

### 8.1 Three independent verdicts

Every report contains all three:

| Verdict | Meaning |
|---|---|
| Execution verdict | Did Hermes/AI-OS perform the permitted workflow correctly? |
| Target verdict | What is the quality/security/readiness condition of the audited system? |
| Governance verdict | What action is authorized next? |

This prevents the dangerous error of treating a successful audit as a successful release.

### 8.2 Minimum public-artifact controls

For a public export or static portal, validation must fail closed on:

- authenticated/private URLs or private destinations;
- checksum mismatch;
- reconciliation/count mismatch;
- schema/manifest drift;
- unclassified or unauthorized records;
- secret material or sensitive data leakage.

The Document Center pilot demonstrated why these checks belong in committed CI, not merely in a staging checklist.

---

## 9. Maturity roadmap

| Stage | Goal | Exit evidence |
|---|---|---|
| 1 — Read-only operations | Repeatable audits and research | Completed GOFFICE + Document Center pilots |
| 2 — Cost observability | Reconciled provider billing and enforced budgets | Three comparable runs with reconciled metrics and stop behavior |
| 3 — Controlled write pilot | Reversible L2 write to an isolated target | Approval, pre/post validation, rollback and knowledge-promotion proof |
| 4 — Release-gated automation | L3 change prepared by AI, approved by human | Dry-run, independent validation, approval and recovery exercise |
| 5 — Production operations | Limited approved automation | Per-integration risk review, monitoring and periodic audit |

The current authorized position is **Stage 1 complete; Stage 2 next; Stages 3–5 are not implied.**

---

## 10. Immediate operating standard

1. Use Obsidian and canonical repositories as the durable knowledge layer; do not duplicate them inside Hermes.
2. Use AI-OS to compile a small, source-grounded context set and enforce task boundaries.
3. Use Hermes + DeepSeek for bounded L0/L1 workflows where traceability outweighs orchestration overhead.
4. Store audit evidence in the AI-OS evidence path/branch only, unless an approved write-path task says otherwise.
5. Treat a discovered defect as a project remediation item, not a Hermes failure.
6. Do not authorize write, publish, deployment or production automation from the read-only pilot results.
7. Make provider-billing reconciliation and budget-stop testing the next gate before broadening adoption.

---

## 11. Related records

- `AI_OPERATING_SYSTEM_BLUEPRINT_V4.md` — integration-first architecture baseline
- GOFFICE2026 full read-only audit evidence (AI-OS v1.6 Hermes pilot)
- Document Center full read-only audit evidence (AI-OS v1.6 Hermes pilot)
- `LOCAL_INTEGRATION_VALIDATION_REPORT.md`
- `CURRENT_STATE.md`

## Final operating statement

> **Memory is canonical knowledge plus governed retrieval—not a larger prompt and not a runtime cache. Hermes is now approved for bounded read-only orchestration; expansion requires measured cost control and separately proven approval-gated write paths.**
