# ADR-0011: Prompt Compiler Runtime (No LLM)

- **Status:** Accepted
- **Date:** 2026-07-30
- **Supersedes (partial):** Extends [ADR-0007](ADR-0007-prompt-compiler-specification-first.md) — specs remain authoritative for contracts; runtime implements them without provider calls.

## Context

v1.1 shipped Prompt Compiler as specification-only. v1.3 needs an executable compiler that turns Project + Goal + Model Profile + Constraints into Head/Subagent prompts and metrics, still without binding to provider SDKs.

## Decision

1. Ship a **stdlib PowerShell runtime** under `prompt-compiler/` with CLI `scripts/compile-prompt.ps1`.
2. Model profiles are **execution-style JSON only** (no project instructions).
3. Context selection returns **references** from indexes, adapters, and bootstrap paths — never copies source knowledge into profile/config.
4. Fail on broken **required** canonical references; warn on optional misses.
5. Deterministic outputs: stable ordering + SHA-256 over stable payload (exclude wall-clock).
6. Still **no** model API calls, Hermes install, or network I/O in the compiler.

## Consequences

- Spec package under `03_Architecture/prompt-compiler/` remains the contract docs.
- Runtime can evolve independently behind the same input/output schemas.
- Provider integration stays deferred (roadmap v1.5 / Hermes).

## Alternatives

- Implement runtime only after Hermes — rejected (blocks local pilot use).
- Call live models to expand prompts — rejected (non-deterministic; credentials; out of scope).

## Links

- Runtime: [prompt-compiler/README.md](../prompt-compiler/README.md)
- Spec: [03_Architecture/prompt-compiler/README.md](../03_Architecture/prompt-compiler/README.md)
- Pilots: [06_Research/pilots/v1.3-prompt-compiler/PILOT_RESULTS.md](../06_Research/pilots/v1.3-prompt-compiler/PILOT_RESULTS.md)
