# ADR-0006: File-Based Indexes Before Vector Search

- **Status:** Accepted
- **Date:** 2026-07-30

## Context

Agents need discoverability across knowledge, projects, ADRs, and skills without introducing vector databases or embeddings in Phase 1/v1.1.

## Decision

Use lightweight JSON indexes under `12_Indexes/` that store **references** (id, title, path, tags) only. Regenerate/validate with standard-library scripts. Vector search is out of scope until a later maturity phase.

## Consequences

- Indexes must not embed full document bodies.
- Broken path references fail validation.
- Search UX remains path/tag oriented (Obsidian + Git).

## Alternatives

- Immediate vector store — rejected (ops burden, secrets/infra).
- No indexes (grep only) — insufficient for agent bootstrap routing.

## Links

- [12_Indexes/README.md](../12_Indexes/README.md)
- [ADR-0002](ADR-0002-github-source-of-truth.md)
