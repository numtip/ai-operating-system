# Benchmark Run: {{RUN_ID}} — {{DATE}}

Single-arm measurement record. Spec: [../../03_Architecture/metrics/METRICS_SPEC.md](../../03_Architecture/metrics/METRICS_SPEC.md). Parent report: [../CONTEXT_EFFICIENCY_BENCHMARK.md](../CONTEXT_EFFICIENCY_BENCHMARK.md).

## Identity

| Field | Value |
|-------|-------|
| Run ID | {{RUN_ID}} |
| Arm | {{baseline \| adapter}} |
| Phase | {{bootstrap \| bootstrap+task}} |
| Corpus root | {{ROOT}} |
| Token method | {{chars/4 \| words*1.3}} |
| AI-OS ref | {{VERSION_OR_COMMIT}} |
| Clock start (ISO) | {{START}} |
| Clock end (ISO) | {{END}} |

## Metrics

| ID | Value | Notes |
|----|-------|-------|
| `files_read` | {{N}} | Distinct paths |
| `tokens_est` | {{N}} | Method above |
| `bootstrap_ms` | {{N}} | Wall-clock ready |
| `memory_hits` | {{N}} | `07_Memory/` (or declared) |
| `index_hits` | {{N}} | Indexes used without full deep-read |

### Optional derived

| ID | Value |
|----|-------|
| `tokens_per_file` | {{N}} |
| `ms_per_file` | {{N}} |

## File list (`files_read`)

| # | Path | Chars or words | tokens_est |
|---|------|----------------|------------|
| 1 | {{PATH}} | {{N}} | {{N}} |
| 2 | {{PATH}} | {{N}} | {{N}} |

## Memory hits

- {{PATH_OR_ID}} — {{why counted as hit}}

## Index hits

- {{PATH_OR_ID}} — {{targets located without full-tree read}}

## Baseline / adapter pairing

| Field | Value |
|-------|-------|
| Paired run ID | {{OTHER_ARM_RUN_ID}} |
| Shared globs / ignores | {{YES — list}} |
| Same token method | {{YES}} |

## Anomalies

{{NONE \| DESCRIPTION}}

## Sign-off

- Measured by: {{WHO}}
- Credible for rollup: {{YES \| NO — reason}}
