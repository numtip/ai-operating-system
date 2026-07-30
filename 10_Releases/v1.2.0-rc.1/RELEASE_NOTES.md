# Release Notes — AI-OS v1.2.0-rc.1

**Tag:** `v1.2.0-rc.1`  
**Date:** 2026-07-30  
**Focus:** Knowledge Index Maturity validated via goffice2026 pilot

## Highlights

- **Project Adapter** — external projects expose six surfaces only (metadata, repo, state, canonical paths, memory, bootstrap). No doc duplication.
- **Bootstrap runtime (spec + sim)** — indexes → locate → minimum context → summary. `simulate-bootstrap.ps1` for goffice2026 returns `ready`.
- **Context metrics** — benchmark templates + `estimate-tokens.ps1` (chars/4).
- **Pilot** — ~98.9% token reduction vs naive docs dump; adapter enforces task-only large docs.
- **ADR-0010** — Project Adapter for external pilots.

## Not in this RC

- Prompt Compiler runtime (v1.3)
- Hermes / VPS / vector search
- Modifications to external goffice2026

## Upgrade notes

1. Pull `main` including five v1.2 feature/docs commits plus RC readiness docs.
2. Run `scripts/validate-v1.1.ps1` and `scripts/simulate-bootstrap.ps1 -ProjectName goffice2026`.
3. Prefer adapter + memory over scanning external `docs/`.

## Evidence

See [RELEASE_READINESS.md](RELEASE_READINESS.md) and audit files in this folder.
