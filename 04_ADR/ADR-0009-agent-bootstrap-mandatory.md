# ADR-0009: Agent Bootstrap as Mandatory Session Protocol

- **Status:** Accepted
- **Date:** 2026-07-30

## Context

Inconsistent session starts caused repeated re-explanation and missed memory/Git checks.

## Decision

Make agent bootstrap **mandatory** for every session:

`Read memory → Read current state → Inspect Git → Load task context → Execute`

Canonical SOP: `09_SOP/AGENT_BOOTSTRAP.md`. Machine-readable manifest: `09_SOP/bootstrap-manifest.json`. Readiness output: `09_SOP/SESSION_READINESS.md`.

## Consequences

- QUICKSTART points to the SOP; SOP is source of truth.
- Minimal required-read policy binds token use.
- Head Agent still owns commits; humans own push/prod/secrets.

## Alternatives

- Optional bootstrap — rejected (drift).
- Full-repo load at start — rejected (token waste).

## Links

- [AGENT_BOOTSTRAP.md](../09_SOP/AGENT_BOOTSTRAP.md)
- [SESSION_BOOTSTRAP.md](../07_Memory/SESSION_BOOTSTRAP.md)
- [ADR-0005](ADR-0005-context-engine-core-layer.md)
