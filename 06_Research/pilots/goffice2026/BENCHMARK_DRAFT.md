# Context Efficiency Benchmark Draft — goffice2026

Fill-in against `11_Templates/CONTEXT_EFFICIENCY_BENCHMARK.md` + `03_Architecture/metrics/METRICS_SPEC.md`.  
**Status:** Draft from pilot measurement (file sizes / chars÷4). Not a timed wall-clock run.

## Meta

| Field | Value |
|-------|-------|
| AI-OS version / ref | v1.2 metrics + bootstrap-runtime specs; vault memory still notes v1.1 |
| Corpus root | `F:\projectAi\goffice2026` (+ AI-OS vault paths for adapter arm) |
| Include / ignore globs | Baseline: `*.md` at root + `docs/**/*.{md,MD}`; ignore `.git`, `node_modules`, `dist` |
| Token method | **chars/4** (Method A) — do not mix |
| Phase | bootstrap |
| Machines / OS | Windows 10 (win32 10.0.26200) |
| Operator | Subagent D (pilot-validate) |
| External tip | `65360ea` |

## Hypothesis

Adapter + ordered bootstrap cuts `tokens_est` by **≥ 90%** vs naive docs-tree dump for goffice2026.

## Arms

| Arm | Description | Run ID |
|-----|-------------|--------|
| Baseline (naive docs dump) | All matching Markdown under project root + `docs/` | `GOFFICE-PILOT-BASE-2026-07-30` |
| Adapter bootstrap (ideal) | Memory → SOP → index → adapter → thin memory → PRODUCT + package.json | `GOFFICE-PILOT-ADP-2026-07-30` |
| Adapter required=true (stress) | Ideal AI-OS base + all adapter-listed required docs (incl. master_reference) | `GOFFICE-PILOT-REQ-2026-07-30` |

---

## Run: Baseline

| Field | Value |
|-------|-------|
| Run ID | GOFFICE-PILOT-BASE-2026-07-30 |
| Arm | baseline |
| Phase | bootstrap |
| Corpus root | `F:\projectAi\goffice2026` |
| Token method | chars/4 |
| `files_read` | **171** |
| `tokens_est` | **263 144** |
| `bootstrap_ms` | *not measured* (size-only pilot) |
| `memory_hits` | 0 |
| `index_hits` | 0 |
| `tokens_per_file` | ~1539 |

Notes: Recurse under `docs/` only (plus root `*.md`). No `node_modules` / `.git` bodies.

---

## Run: Adapter ideal

| Field | Value |
|-------|-------|
| Run ID | GOFFICE-PILOT-ADP-2026-07-30 |
| Arm | adapter |
| Phase | bootstrap |
| Token method | chars/4 |
| `files_read` | **9** |
| `tokens_est` | **2 841** |
| `bootstrap_ms` | *not measured* |
| `memory_hits` | 3 (SYSTEM, CURRENT_STATE, projects/goffice2026.md) |
| `index_hits` | 1 (project_index.json — currently empty; counted as read) |
| `tokens_per_file` | ~316 |

### File list (`files_read`)

| # | Path | Chars | tokens_est |
|---|------|------:|----------:|
| 1 | `07_Memory/SYSTEM_MEMORY.md` | 1261 | 316 |
| 2 | `07_Memory/CURRENT_STATE.md` | 1217 | 305 |
| 3 | `09_SOP/AGENT_BOOTSTRAP.md` | 1301 | 326 |
| 4 | `03_Architecture/PROJECT_CONTEXT_LOADING.md` | 1573 | 394 |
| 5 | `12_Indexes/project_index.json` | ~208 | 52 |
| 6 | `01_Projects/goffice2026/ADAPTER.md` | 1918 | 480 |
| 7 | `07_Memory/projects/goffice2026.md` | 363 | 91 |
| 8 | `goffice2026/PRODUCT.md` | 1952 | 488 |
| 9 | `goffice2026/package.json` | 1555 | 389 |
| | **Total** | | **2841** |

---

## Run: Adapter required=true (anti-pattern stress)

| Field | Value |
|-------|-------|
| Run ID | GOFFICE-PILOT-REQ-2026-07-30 |
| Arm | adapter (misconfigured) |
| `files_read` | **11** |
| `tokens_est` | **32 918** |
| Dominant cost | `docs/GOFFICE2026_NEW_PROJECT_MASTER_REFERENCE.md` ≈ **22 611** tok |

Use to show why `required: true` on large refs defeats the adapter.

---

## Results (primary)

| Metric | Baseline | Adapter ideal | Delta / reduction |
|--------|----------|---------------|-------------------|
| `files_read` | 171 | 9 | −162 (−94.7%) |
| `tokens_est` | 263 144 | 2 841 | `context_reduction_pct` = **98.9%** |
| `bootstrap_ms` | n/a | n/a | deferred |
| `memory_hits` | 0 | 3 | +3 |
| `index_hits` | 0 | 1 | +1 |

```text
100 * (1 - 2841 / 263144) ≈ 98.9%
```

Stress vs baseline: `100 * (1 - 32918 / 263144) ≈ 87.5%` — still better than naive, but **~11.6×** worse than ideal.

## Interpretation

- Pass criteria (draft): reduction ≥ 90%, `files_read` ≤ 15 for identity bootstrap  
- Outcome: **PASS** (ideal arm) / **WARN** (required=true arm)  
- Notes: Index empty is a functional blocker for runtime discovery even though token math for ideal path is strong; wall-clock `bootstrap_ms` not yet collected.

## Artifacts

- This draft: `06_Research/pilots/goffice2026/BENCHMARK_DRAFT.md`
- Validation: `VALIDATION_REPORT.md`
- Spec: `03_Architecture/metrics/METRICS_SPEC.md`

## Follow-ups

- [ ] Regenerate `project_index.json` and re-run discovery simulation
- [ ] Measure `bootstrap_ms` with `scripts/simulate-bootstrap.ps1` once present
- [ ] Demote master_reference in adapter; re-measure REQ arm
- [ ] Optional second baseline: “shallow” 38-file docs sample (~89 197 tok) for sensitivity
