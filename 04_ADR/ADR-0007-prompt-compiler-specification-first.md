# ADR-0007: Prompt Compiler as Specification-First

- **Status:** Accepted
- **Date:** 2026-07-30

## Context

Multi-model routing needs a stable contract before any API integration. Implementing calls too early locks the system to providers.

## Decision

Ship a **specification-only** Prompt Compiler under `03_Architecture/prompt-compiler/`: input schema, routing fields, output contract, model profiles, short-prompt standard, and subagent task prompt template. No API calls or SDKs in v1.1.

## Consequences

- Profiles (GPT, DeepSeek, Claude, Gemini, Hermes) are declarative.
- Hermes profile is placeholder until Phase 2 / v1.5.
- Runtime compiler is roadmap v1.3.

## Alternatives

- Hard-code provider SDKs now — rejected.
- Skip compiler and rely on ad-hoc prompts — rejected (not reusable).

## Links

- [prompt-compiler/README.md](../03_Architecture/prompt-compiler/README.md)
- [ADR-0004](ADR-0004-hermes-deferred-phase-2.md)
