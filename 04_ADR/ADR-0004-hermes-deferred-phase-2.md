# ADR-0004: Hermes Deferred to Phase 2

## Status

Accepted

## Date

2026-07-30

## Context

Hermes (orchestrator) enables multi-agent / runtime orchestration but adds install, config, and operational surface. Phase 1 priority is a stable knowledge and memory foundation before orchestration.

## Decision

Defer the Hermes orchestrator to Phase 2. Phase 1 is Obsidian + Git + Knowledge/Memory only. Do not install Hermes now.

## Consequences

- Phase 1 stays focused and installable with fewer dependencies.
- Orchestration, agent routing, and Hermes-specific ops are out of scope until Phase 2.
- Docs and workflows must not assume Hermes is present in Phase 1.
- Revisit when knowledge foundation is accepted.

## Alternatives

- **Install Hermes in Phase 1** — Rejected; distracts from knowledge foundation.
- **Partial Hermes stub/config only** — Rejected; still implies presence and maintenance.

## Links

- [ADR-0001 Local-First Development](ADR-0001-local-first-development.md)
- [README](README.md)
