# Context Efficiency Metrics

Why measure context load for AI-OS.

## Purpose

AI-OS is file-based: agents assemble a working set from Markdown, memory, and indexes — not a full vault scan. Context efficiency measures whether that bootstrap stays **small, fast, and targeted**.

Without metrics, “minimal load” is aspirational. With them, adapter bootstrap can be compared to a naive full-tree baseline and regressions caught across releases.

## What we optimize

| Goal | Signal |
|------|--------|
| Fewer files in the working set | Files read |
| Lower prompt cost | Tokens estimated |
| Faster session start | Bootstrap time |
| Adapter beats dump-all | Context reduction |
| Reuse of durable facts | Memory hits |
| Prefer indexes over deep reads | Index hits |

## Spec and templates

- Measures and formulas: [METRICS_SPEC.md](METRICS_SPEC.md)
- Multi-run benchmark report: [../../11_Templates/CONTEXT_EFFICIENCY_BENCHMARK.md](../../11_Templates/CONTEXT_EFFICIENCY_BENCHMARK.md)
- Single-run record: [../../11_Templates/metrics/BENCHMARK_RUN.md](../../11_Templates/metrics/BENCHMARK_RUN.md)

## Constraints

- Spec/docs only in this folder — no LLM calls, no database, no runtime service.
- Manual or script-assisted measurement; report values in the templates above.
- Do not invent token counts from model APIs; use the documented heuristic in METRICS_SPEC.
