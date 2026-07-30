# Changelog

All notable changes to AI Operating System are documented here.

## [Unreleased]

## [v1.2.0-rc.1] — 2026-07-30

### Added

- Project Adapter specification + goffice2026 adapter (link-don't-copy)
- Bootstrap runtime specification + `scripts/simulate-bootstrap.ps1`
- Context efficiency metrics + benchmark templates + `scripts/estimate-tokens.ps1`
- goffice2026 pilot validation under `06_Research/pilots/goffice2026/`
- ADR-0010 Project Adapter for external pilots
- RC audit pack under `10_Releases/v1.2.0-rc.1/`

### Changed

- `project_index.json` lists goffice2026
- System/current memory and entry docs aligned to v1.2 RC
- Large external master_reference demoted from default bootstrap

## [v1.1.0-alpha.1] — 2026-07-30

### Added

- Context Engine foundation (`Context → Memory → Task → Decision → Output`)
- Agent bootstrap SOP, checklist, manifest, readiness standard
- Prompt Compiler specification (schemas, routing, profiles; no API runtime)
- Knowledge indexes under `12_Indexes/` + generate/validate scripts
- Memory compression policy (threshold 25) + summary templates
- `AI_OS_MANIFESTO.md`
- ADR-0005 … ADR-0009
- Roadmap through v2.0

### Changed

- Architecture overview and system memory aligned to v1.1
- Structure validator extended for v1.1 required paths

## [v1.0.0-alpha.1] — 2026-07-30

### Added

- Vault structure, governance, memory system, templates
- ADR-0001 … ADR-0004
- Structure validation scripts
