# Changelog

All notable changes to AI Operating System are documented here.

## [Unreleased]

## [v1.4.0-alpha.1] — 2026-08-01

### Added

- **Context Optimizer** — deterministic ranking/selection of context references; duplicate + low-value elimination; file/token budget enforcement (default `max_files = min(profile max_context_refs, 10)`, overridable via profile `context_budget`); mandatory (required) context never dropped
- **Prompt Quality Gate** — validates subagent required sections, prohibited actions, tool policy (no-network / read-only-first), and bounded output; returns actionable `quality_gate:` errors (no silent failure)
- Structured metrics: `metrics.optimization` (files_selected/rejected, budget, required_count) and `metrics.quality_gate` (errors/warnings); `compiler_metadata.optimizer_version`
- `context_budget` field to all model profiles + profile schema
- Release pack under `10_Releases/v1.4.0-alpha.1/`

### Changed

- goffice2026 pilot context reduced **12 → 10 files** (8 required preserved), tokens ~1577 → 1551
- document-center pilot context = 10 files (5 required preserved)
- Roadmap v1.4 re-scoped to Context Optimizer + Prompt Quality Gate (was "Agent Bootstrap Automation")

### Fixed

- Required context refs preserved on normalized-path collision (mandatory-context invariant)
- Profile budget values parsed via `[int]::TryParse` (malformed values no longer crash compile)
- Quality gate negation handling (prohibitions like "do not push" no longer false-positive)
- Unquoted hardcoded secret detection

## [v1.3.0-alpha.1] — 2026-07-30

### Added

- Prompt Compiler **runtime** (`prompt-compiler/`, `scripts/compile-prompt.ps1`) — no LLM/API
- Model execution profiles: generic-reasoning, deepseek-v4-pro/flash, claude-coding, cursor-coding
- Bounded subagent prompt generation + context selection via indexes/adapters/bootstrap
- Deterministic metrics (incl. SHA-256) and automated compiler tests
- Minimum `document-center` project adapter for pilot isolation
- Pilot results under `06_Research/pilots/v1.3-prompt-compiler/`
- ADR-0011 Prompt Compiler Runtime (No LLM)

### Changed

- Roadmap v1.3 marked Complete (MVP)
- Prompt compiler architecture README points at executable runtime
- System/current memory aligned to v1.3

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
