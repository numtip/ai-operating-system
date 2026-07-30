# ADR-0005: Context Engine as a Core Architecture Layer

- **Status:** Accepted
- **Date:** 2026-07-30

## Context

Agents reloaded chat history and scattered files without a stable chain from intent to outcome. Oversized prompts replaced durable structure.

## Decision

Treat a file-based **Context Engine** as a core architecture layer:

`Context → Memory → Task → Decision → Output`

Canonical overview: `03_Architecture/CONTEXT_ENGINE.md`. Templates live under `11_Templates/context/`. No runtime service in v1.1.

## Consequences

- Session work must attach or reference context packages.
- Memory and ADRs remain sources of truth; context packages link, not duplicate.
- Runtime orchestration deferred (see Prompt Compiler / Hermes roadmap).

## Alternatives

- Prompt-only context packing — rejected (not durable or reviewable).
- Database-backed context store — deferred (local-first Markdown/Git first).

## Links

- [CONTEXT_ENGINE.md](../03_Architecture/CONTEXT_ENGINE.md)
- [ADR-0008](ADR-0008-memory-compression-threshold.md)
- [ADR-0009](ADR-0009-agent-bootstrap-mandatory.md)
