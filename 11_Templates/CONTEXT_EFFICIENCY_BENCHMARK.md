# Context Efficiency Benchmark: {{TITLE}} — {{DATE}}

Fill-in report. Spec: [../03_Architecture/metrics/METRICS_SPEC.md](../03_Architecture/metrics/METRICS_SPEC.md). One report per series; attach one `BENCHMARK_RUN` per arm/run.

## Meta

| Field | Value |
|-------|-------|
| AI-OS version / ref | {{VERSION_OR_COMMIT}} |
| Corpus root | {{REPO_OR_PROJECT_ROOT}} |
| Include / ignore globs | {{GLOBS}} |
| Token method | {{chars/4 \| words*1.3}} — **do not mix in this report** |
| Phase | {{bootstrap \| bootstrap+task}} |
| Machines / OS | {{ENV}} |
| Operator | {{WHO}} |

## Hypothesis

{{WHAT_WE_EXPECT — e.g. adapter bootstrap cuts tokens ≥ 70% vs naive full-tree}}

## Arms

| Arm | Description | Run record |
|-----|-------------|------------|
| Baseline (naive full-tree) | {{SCOPE}} | [metrics/BENCHMARK_RUN.md](metrics/BENCHMARK_RUN.md) → {{RUN_ID_BASELINE}} |
| Adapter bootstrap | Ordered load / project-adapter | → {{RUN_ID_ADAPTER}} |

Copy `11_Templates/metrics/BENCHMARK_RUN.md` per run; link or paste IDs above.

## Results (primary)

| Metric | Baseline | Adapter | Delta / reduction |
|--------|----------|---------|-------------------|
| `files_read` | {{N}} | {{N}} | {{Δ or %}} |
| `tokens_est` | {{N}} | {{N}} | `context_reduction_pct` = {{%}} |
| `bootstrap_ms` | {{N}} | {{N}} | {{Δ ms}} |
| `memory_hits` | {{N}} | {{N}} | {{Δ}} |
| `index_hits` | {{N}} | {{N}} | {{Δ}} |

`context_reduction_pct` (tokens preferred):

```text
100 * (1 - adapter_tokens_est / baseline_tokens_est) = {{PCT}}
```

## Interpretation

- Pass criteria: {{e.g. reduction ≥ X%, bootstrap_ms ≤ Y, files_read ≤ Z}}
- Outcome: {{PASS \| FAIL \| INCONCLUSIVE}}
- Notes: {{REGRESSIONS, SKEW, ENV NOISE}}

## Artifacts

- Run sheets: {{PATHS}}
- File lists (optional): {{PATHS}}
- Related memory/index versions: {{REFS}}

## Follow-ups

- [ ] {{ACTION}}
