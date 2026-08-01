# ADR-0012: Automated Bootstrap Gate (v1.5)

- **Status:** Accepted
- **Date:** 2026-08-01
- **Supersedes (partial):** Extends [ADR-0009](ADR-0009-agent-bootstrap-mandatory.md) — protocol stays; execution now machine-enforced.

## Context

ADR-0009 made bootstrap mandatory by convention. Sessions still drifted: memory reads were manual, readiness was prose, and nothing blocked an agent that skipped required reads.

## Decision

1. Ship an automated **Bootstrap Gate** checker (`scripts/check-bootstrap.ps1`) that:
   - Loads `09_SOP/bootstrap-manifest.json` (v1.2)
   - Verifies every `required_read` path exists
   - Verifies Git inspection happened (branch + dirty count captured)
   - Verifies readiness artifact + (optionally) project adapter/index resolution
   - Emits human text or JSON; exit code 0/1 (WARN never fails unless `-Strict`)
2. **FAIL gates block execution**; WARN must be acknowledged.
3. Manifest version bumped to `1.2` with `readiness.required_gates` and `enforcement` fields.

## Consequences

- Bootstrap becomes deterministic and auditable (JSON evidence).
- Agents may not begin work with unresolved required reads.
- SOP/checklist reference the gate; README not duplicated.

## Alternatives

- Manual discipline only (v1.1) — rejected (drift observed).
- Full orchestration runtime — deferred (v1.6 / Hermes).

## Links

- [check-bootstrap.ps1](../scripts/check-bootstrap.ps1)
- [bootstrap-manifest.json](../09_SOP/bootstrap-manifest.json)
- [SESSION_READINESS.md](../09_SOP/SESSION_READINESS.md)
- [AGENT_BOOTSTRAP.md](../09_SOP/AGENT_BOOTSTRAP.md)
- [CHANGELOG.md](../CHANGELOG.md) (`[v1.5.0-alpha.1]`)
- Release pack: [10_Releases/v1.5.0-alpha.1/](../10_Releases/v1.5.0-alpha.1/)
- [ADR-0009](ADR-0009-agent-bootstrap-mandatory.md)
