# Release Notes — AI-OS v1.4.0-alpha.1

**Tag:** `v1.4.0-alpha.1`
**Date:** 2026-08-01
**Focus:** Context Optimizer + Prompt Quality Gate

## Highlights

- **Context Optimizer** — deterministic ranking/selection of context references; duplicate + low-value elimination; file/token budget enforcement (default `max_files = min(profile max_context_refs, 10)`); mandatory (required) context never dropped.
- **Prompt Quality Gate** — validates subagent required sections, prohibited actions, tool policy (no-network / read-only-first), and bounded output before agent execution; returns actionable `quality_gate:` errors (no silent failure).
- **Structured metrics** — `metrics.optimization` (files_selected/rejected, budget, required_count) and `metrics.quality_gate` (errors/warnings); `compiler_metadata.optimizer_version`.
- **Pilot result** — goffice2026 context reduced **12 → 10 files** (8 required preserved), tokens ~1577 → 1551.
- **Vendor-neutral** — no hardcoded model/vendor names in new logic.

## Not in this alpha

- Agent Bootstrap Automation (roadmap v1.4 item — deferred; see ROADMAP)
- Hermes / VPS / vector search
- Any remote mutation (not pushed)

## Upgrade notes

1. Pull `main` including V1.4 feature + RC hardening commits.
2. Run `scripts/validate-structure.ps1` and `prompt-compiler/tests/run-tests.ps1` (46/46).
3. Optional: add `context_budget` (`max_files`/`max_tokens`) to any profile to override defaults.

## Evidence

- Tests: `SUMMARY passed=46 failed=0`
- Build: `validate-structure.ps1` → PASS
- Smoke: goffice2026/deepseek-v4-pro → status ok, files=10, quality_gate errors=0
