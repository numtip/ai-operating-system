# ADR-0001: Local-First Development

## Status

Accepted

## Date

2026-07-30

## Context

AI Operating System v1 Phase 1 builds the knowledge foundation (vault, memory, workflows). Production hosting and remote infrastructure would add setup cost and delay learning loops without improving knowledge quality.

## Decision

Use local-first development for Phase 1. All work runs on the local machine. No VPS or production deploy is required for the knowledge foundation.

## Consequences

- Faster iteration and lower operational overhead.
- Knowledge and tooling remain portable via Git.
- Production deploy, remote agents, and hosting decisions are deferred.
- Phase 1 acceptance does not depend on cloud availability.

## Alternatives

- **VPS-first / production deploy now** — Rejected; premature for Phase 1 knowledge work.
- **Hybrid local + always-on remote** — Rejected; adds ops cost without Phase 1 benefit.

## Links

- [ADR-0004 Hermes Deferred](ADR-0004-hermes-deferred-phase-2.md)
- [README](README.md)
