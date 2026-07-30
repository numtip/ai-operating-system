# Findings — goffice2026 pilot

Concise validation table. Detail: [VALIDATION_REPORT.md](VALIDATION_REPORT.md). Metrics draft: [BENCHMARK_DRAFT.md](BENCHMARK_DRAFT.md).

| # | Area | Finding | Severity | Action |
|---|------|---------|----------|--------|
| 1 | Index | `project_index.json` empty / stale; bootstrap-runtime cannot resolve goffice2026 by name | High | Regenerate index |
| 2 | Adapter | ADAPTER.md present with correct tip/remote/canonical paths | OK | Maintain link-only |
| 3 | Unnecessary read | `master_reference` marked required (~22.6k tok) | High | Demote to on-demand |
| 4 | Memory | Project memory exists but lacks blockers / write-bounds | Medium | Enrich pointers |
| 5 | Broken ref | `scripts/simulate-bootstrap.ps1` linked but missing | Medium | Add script or fix link |
| 6 | Efficiency | Ideal bootstrap ~2.8k tok vs naive docs tree ~263k tok (~98.9% reduction) | OK | Codify ordered set |
| 7 | Version drift | Memory says v1.1; metrics/bootstrap say v1.2 | Low | Align labels |
| 8 | Duplication | No PRODUCT/DESIGN copy in vault (good); risk is agent dumping external `docs/` | Medium | Enforce stop rules |
