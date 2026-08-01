# Release Readiness — AI-OS v1.4.0-alpha.1

**Status:** READY_FOR_V1.4.0-ALPHA.1

## Validation
- [x] Structure: `scripts/validate-structure.ps1` → PASS
- [x] Unit tests: `prompt-compiler/tests/run-tests.ps1` → 46/46
- [x] Smoke: `scripts/compile-prompt.ps1 -Project goffice2026 -ModelProfile deepseek-v4-pro` → status ok, files=10, quality_gate errors=0
- [x] Regression V1.0–V1.3: 25 original assertions pass unchanged
- [x] Docs / memory updated

## Acceptance checklist
- [x] Deterministic ranking
- [x] Duplicate elimination
- [x] File/token budget enforcement
- [x] Mandatory context preservation
- [x] Actionable validation errors
- [x] Structured metrics
- [x] Pilot context ≤ 10 files (12 → 10)
- [x] Vendor-neutral

## Rollback Notes
1. Restore baseline: commit `481ed61` (pre-V1.4) / tag `v1.3.0-alpha.1`
2. Known side effects: optional low-value context refs trimmed on existing pilots (intended); selector cap (12) vs optimizer cap (10) inconsistency documented.

## Checklist
- [x] Version bumped (runtime 1.4.0)
- [x] Release notes filed under `10_Releases/v1.4.0-alpha.1/`
- [ ] Tag `v1.4.0-alpha.1` created (deferred — awaiting push approval)
- [ ] Stakeholders notified (if required)
