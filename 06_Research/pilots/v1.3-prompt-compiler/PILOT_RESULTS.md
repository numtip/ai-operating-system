# Pilot Results — AI-OS v1.3 Prompt Compiler Runtime

**Date:** 2026-07-30  
**Runtime:** `scripts/compile-prompt.ps1` + `prompt-compiler/runtime/Compile-Prompt.ps1`  
**LLM/API:** none

## Pilot 1 — goffice2026

| Field | Value |
|-------|-------|
| Goal | Audit production readiness without modifying the external repository. |
| Model profile | `deepseek-v4-pro` |
| Status | ok |
| Subagents | `qa-structure`, `qa-docs-canonical`, `qa-risk-gates` |
| External write | denied (read-only) |
| Artifacts | [goffice2026/](goffice2026/) |

### Metrics

| Metric | Value |
|--------|-------|
| compiled_prompt_size_chars | 6308 |
| estimated_tokens | 1577 |
| context_files_selected | 12 |
| index_hits | 5 |
| warnings | 0 |
| subagent_count | 3 |
| deterministic_hash | `733d0d314e6e0d09ed9449012c098b6699c157aaf240cda56c2e986b4c7cfe6d` |

### Expected checks

- [x] Audit-oriented Head Agent prompt
- [x] Bounded QA subagents (no overlap ids)
- [x] No external repository write permission
- [x] No absolute machine paths in compiled prompt

## Pilot 2 — document-center

| Field | Value |
|-------|-------|
| Goal | Inspect publication pipeline readiness and identify blocking issues. |
| Model profile | `claude-coding` |
| Status | ok |
| Subagents | `inspect-pipeline`, `inspect-blockers` |
| Adapter | minimum in-vault adapter created for pilot |
| Artifacts | [document-center/](document-center/) |

### Metrics

| Metric | Value |
|--------|-------|
| compiled_prompt_size_chars | 5198 |
| estimated_tokens | 1300 |
| context_files_selected | 14 |
| index_hits | 10 |
| warnings | 2 (optional missing product/pipeline docs) |
| subagent_count | 2 |
| deterministic_hash | `8e10defefc04262594603d8e1debaa7c0e3b784bf9b23b568122fec1df9914b3` |

### Expected checks

- [x] Correct project lookup (`document-center`)
- [x] Relevant context only (adapter, memory, indexes, bootstrap)
- [x] No copied goffice2026 product instructions (forbid cross-project load)
- [x] Optional missing context → warn, not fail

## Isolation

| Check | Result |
|-------|--------|
| goffice2026 context not used as document-center product source | PASS |
| document-center prompt forbids loading goffice2026 adapter/memory | PASS |
| Deterministic recompile (same inputs → same hash) | PASS (test suite) |

## Reproduce

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compile-prompt.ps1 `
  -Project goffice2026 `
  -Goal "Audit production readiness without modifying the external repository." `
  -ModelProfile deepseek-v4-pro `
  -OutDir 06_Research/pilots/v1.3-prompt-compiler/goffice2026

powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compile-prompt.ps1 `
  -Project document-center `
  -Goal "Inspect publication pipeline readiness and identify blocking issues." `
  -ModelProfile claude-coding `
  -Constraints "do not load goffice2026 instructions","read-only" `
  -OutDir 06_Research/pilots/v1.3-prompt-compiler/document-center

powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests.ps1
```
