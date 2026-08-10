# ADR-0013: Integration-First Hermes Runtime Architecture

## Status

Accepted for v1.6 integration branch

## Date

2026-08-09

## Context

AI-OS v1.0-v1.5 established the knowledge foundation, context engine, deterministic prompt compiler, context optimizer, prompt quality gate, and automated bootstrap gate. The original roadmap intentionally deferred Hermes until this foundation was stable.

The foundation is now complete through v1.5.0-alpha.1. The next phase should avoid rebuilding mature capabilities already provided by the surrounding ecosystem. AI-OS should become the governed integration and operating layer that connects orchestration, knowledge, source control, enterprise systems, automation, infrastructure, and interchangeable AI models.

## Decision

Adopt an integration-first architecture for v1.6 and later:

- Hermes is the preferred orchestration/runtime layer, subject to installation approval and a compatibility spike.
- Obsidian remains the human-facing knowledge interface.
- GitHub remains the versioned source of truth for AI-OS specifications, ADRs, skills, release records, and governed knowledge artifacts.
- Microsoft 365 remains the enterprise document/collaboration layer rather than being duplicated inside AI-OS.
- n8n remains the workflow automation layer where deterministic integration workflows are more appropriate than agent reasoning.
- Ubuntu/Docker/Cloudflare remain the deployment and network foundation.
- AI providers/models remain interchangeable intelligence services selected by policy and task fit.
- Existing AI-OS context compiler, optimizer, quality gate, bootstrap gate, memory conventions, and ADR governance are retained as the governance/specification layer unless a Hermes capability demonstrably supersedes them.

## Runtime Boundary

AI-OS will not build a second general-purpose orchestrator, vector database, workflow engine, document platform, or model platform by default. New runtime components require evidence that an existing approved component cannot satisfy the requirement.

## v1.6 Execution Strategy

1. Reconcile v1.5 assets with Hermes integration requirements.
2. Define the Hermes adapter contract before installation.
3. Run a local-first, reversible compatibility spike.
4. Integrate one low-risk pilot project through the existing bootstrap and quality gates.
5. Measure context size, task success, latency, cost, auditability, and operator effort.
6. Only then decide whether Hermes becomes the default runtime.

## Approval Boundary

This ADR does not authorize installation on a workstation/VPS, secrets changes, production deployment, DNS changes, or destructive migration. Those remain human-approved operations.

## Consequences

### Positive

- Reduces duplicated engineering and maintenance.
- Preserves vendor neutrality at the intelligence layer.
- Makes the v1.0-v1.5 work reusable as governance rather than throwaway runtime code.
- Enables gradual adoption with measurable pilots and rollback.

### Trade-offs / Risks

- Hermes becomes an external dependency and may not map cleanly to existing bootstrap/context contracts.
- Some current runtime code may later become adapter-only or compatibility code.
- Multiple systems of record can drift unless ownership boundaries are explicit.
- Enterprise integrations increase identity, secret, audit, and permission complexity.

## Supersedes / Extends

This ADR does not invalidate ADR-0004. ADR-0004 correctly deferred Hermes during Phase 1. This ADR records that the prerequisite foundation is now sufficiently mature to begin the Phase 2 integration work.

## Related

- ADR-0002 GitHub Source of Truth
- ADR-0003 Obsidian Knowledge Interface
- ADR-0004 Hermes Deferred to Phase 2
- ADR-0005 Context Engine Core Layer
- ADR-0011 Prompt Compiler Runtime No LLM
- ADR-0012 Automated Bootstrap Gate
- `03_Architecture/ROADMAP.md`
