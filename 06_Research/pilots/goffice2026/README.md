# Pilot: goffice2026

AI-OS v1.2 architecture pilot against external project **goffice2026**. Recommendations only — this folder does not modify the external repo.

## Target

| Field | Value |
|-------|-------|
| Local path | `F:\projectAi\goffice2026` |
| Remote | https://github.com/numtip/goffice2026.git |
| Branch | `master` |
| Tip (pilot) | `65360ea` |
| AI-OS adapter | `01_Projects/goffice2026/ADAPTER.md` |
| AI-OS memory | `07_Memory/projects/goffice2026.md` |

## Artifacts (this pilot)

| File | Purpose |
|------|---------|
| [VALIDATION_REPORT.md](VALIDATION_REPORT.md) | Bootstrap / memory / duplication / refs / unnecessary-read validation + recommendations |
| [FINDINGS.md](FINDINGS.md) | Concise findings table |
| [BENCHMARK_DRAFT.md](BENCHMARK_DRAFT.md) | Context-efficiency draft (ideal adapter vs naive docs dump) |

## Constraints honored

- Read-only on `F:\projectAi\goffice2026` (targeted headers / sizes only)
- No writes under goffice2026
- No secrets from `.env`
- No commit / push from this pilot

## Related AI-OS specs

- `09_SOP/AGENT_BOOTSTRAP.md`
- `03_Architecture/CONTEXT_ENGINE.md`
- `03_Architecture/PROJECT_CONTEXT_LOADING.md`
- `03_Architecture/project-adapter/SPEC.md`
- `03_Architecture/bootstrap-runtime/SPEC.md`
- `03_Architecture/metrics/METRICS_SPEC.md`
- `04_ADR/ADR-0010-project-adapter-external-pilots.md`
