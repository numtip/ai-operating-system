# ADR-0014: Pin Hermes Product — NousResearch/hermes-agent v2026.8.3

## Status

Accepted for v1.6 integration branch (product pin; install still approval-gated)

## Date

2026-08-09

## Supersedes

Resolves the ambiguity recorded in `06_Research/pilots/v1.6-hermes/HERMES_INSTALL_PREFLIGHT.md` (2026-08-09, STOPPED because no product/source/version was pinned). This ADR pins the product; it does **not** authorize installation.

## Context

Gate B install approval previously could not proceed because "Hermes" was defined only as an architectural role (ADR-0013, Blueprint V4 §6) with no concrete product identity. The owner has now selected a runtime candidate: **NousResearch/hermes-agent**, tag **v2026.8.3**. This ADR records the immutable pin and its verification so a later, separately-approved install can be genuinely pinned and reversible.

## Decision — Product Pin

| Field | Value |
|---|---|
| Product | NousResearch Hermes Agent (agent orchestration runtime) |
| Official repository | `https://github.com/NousResearch/hermes-agent` |
| Release tag | `v2026.8.3` (annotated tag; tag object SHA `7de39e700d2c329e15d32eb0b96e2f7cdd9fbdb2`) |
| **Immutable commit SHA** | **`3c27eb6234bf91b8ceee9e9071591b31e9b148cb`** (commit message: `chore: release v0.20.0 (2026.8.3)`) |
| Release/tag signature | Tag **SSH-signed** (`verification.verified=true`, reason `valid`, ed25519; key fingerprint `x9xNOpeJhoEAY2gWhmWHZROC3QF3VjOEbmNo9vQ8y2A`). Underlying commit itself is **unsigned** (`reason: unsigned`) — pin by tag signature + SHA, not by commit signature alone |
| License | **MIT** (Copyright (c) 2025 Nous Research; confirmed from repo LICENSE at tag `v2026.8.3`) |
| Official install docs | README: `git clone https://github.com/NousResearch/hermes-agent.git` → `./setup-hermes.sh` → `./hermes`; official one-liner `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash` (PowerShell `iex (irm ...install.ps1)`) |
| PyPI status | `hermes-agent` on PyPI (MIT), latest published **0.19.0** (2026-07-20). **Tag v2026.8.3 / v0.20.0 is NOT yet on PyPI** → sandbox install MUST use the git tag, never PyPI |
| Verification date/method | 2026-08-09; WebFetch/WebSearch only (no installs). Sources: `github.com/NousResearch/hermes-agent` (tags/releases), GitHub API (`git/refs/tags/v2026.8.3`, `git/tags/7de39e70…`, `git/commits/3c27eb62…`), raw `LICENSE`, `pypi.org/project/hermes-agent` |

## Scope of this ADR

- Pins the product, tag, commit, signature status, license, and install-source constraint.
- Records the preflight decision framework (see `HERMES_PREFLIGHT_REPORT.md`).
- Does **NOT** authorize: installation, dependency download, runtime activation, network access, credentials, or any production/external mutation. Those remain separately approval-gated (ADR-0013 Approval Boundary; Blueprint V4 §21.4).

## Consequences

### Positive
- Removes the ambiguity blocker; any future install has a single immutable target.
- Reversible by construction: tag + SSH-signed tag + full commit SHA pin makes the sandbox auditable and rollback-verifiable.

### Trade-offs / Risks
- Tag is signed but underlying commit is unsigned — trust rests on the tag signature + SHA pin.
- `v2026.8.3` not on PyPI → install from git tag only (no PyPI package for this exact version yet).
- Any future tag/commit mismatch must STOP and roll back (Rollback Plan §6, extended in preflight).

## Related

- ADR-0013 Integration-First Hermes Runtime
- ADR-0004 Hermes Deferred to Phase 2 (historical, not invalidated)
- `03_Architecture/HERMES_ADAPTER_CONTRACT.md`
- `03_Architecture/HERMES_ROLLBACK_PLAN.md`
- `06_Research/pilots/v1.6-hermes/HERMES_INSTALL_PREFLIGHT.md` (prior STOP record)
- `06_Research/pilots/v1.6-hermes/HERMES_PREFLIGHT_REPORT.md`
- `06_Research/pilots/v1.6-hermes/LOCAL_INTEGRATION_VALIDATION_REPORT.md`
