# Findings — goffice2026 pilot

Concise validation table. Detail: [VALIDATION_REPORT.md](VALIDATION_REPORT.md). Metrics draft: [BENCHMARK_DRAFT.md](BENCHMARK_DRAFT.md).

**Remediation status (RC 2026-07-30):** High/Medium blockers below were fixed during Head Agent integration. Historical findings retained for traceability.

| # | Area | Finding | Severity | Status |
|---|------|---------|----------|--------|
| 1 | Index | `project_index.json` empty / stale | High | **Remediated** — `project-goffice2026` present |
| 2 | Adapter | ADAPTER.md present, link-only | OK | Maintain |
| 3 | Unnecessary read | `master_reference` required | High | **Remediated** — demoted to optional/task-only |
| 4 | Memory | Thin memory; needed blockers/write-bounds | Medium | **Remediated** — memory updated |
| 5 | Broken ref | `simulate-bootstrap.ps1` missing | Medium | **Remediated** — script present |
| 6 | Efficiency | ~2.8k vs ~263k tok (~98.9% reduction) | OK | Codified in pilot + sim |
| 7 | Version drift | Memory v1.1 vs work v1.2 | Low | **Remediated** — aligned to v1.2 RC |
| 8 | Duplication | Risk of dumping external `docs/` | Medium | Enforced via adapter required flags |
