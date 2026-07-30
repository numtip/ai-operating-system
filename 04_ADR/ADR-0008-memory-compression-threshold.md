# ADR-0008: Memory Compression Threshold

- **Status:** Accepted
- **Date:** 2026-07-30

## Context

Session handoffs accumulate. Unbounded session files increase agent load and contradict token-reduction rules.

## Decision

Adopt a memory compression framework under `07_Memory/compression/` with default **session_count_threshold = 25**. When session markdown count under `07_Memory/sessions/` meets or exceeds the threshold, agents must summarize, archive per policy, and keep executive/open-decisions/lessons summaries current. Enforcement script: `scripts/check-session-threshold.ps1`.

## Consequences

- Threshold is configurable via `THRESHOLD.json`.
- Compression produces human-readable summaries; raw sessions may move to Archive per policy.
- Does not delete without human approval.

## Alternatives

- No threshold — rejected (context bloat).
- Auto-delete old sessions — rejected (traceability risk).

## Links

- [COMPRESSION_POLICY.md](../07_Memory/compression/COMPRESSION_POLICY.md)
- [ADR-0005](ADR-0005-context-engine-core-layer.md)
