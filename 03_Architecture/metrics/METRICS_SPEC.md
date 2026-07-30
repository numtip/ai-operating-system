# Context Efficiency — Metrics Spec

AI-OS v1.2. File-based measurement only. No LLM, no DB, no vendor tokenizer required.

## Scope

| In | Out |
|----|-----|
| Files an agent opens during bootstrap / task assembly | Chat transcript length outside declared working set |
| Estimated tokens for those files | Exact model-billed tokens (optional later, not required) |
| Wall-clock bootstrap duration | Downstream task execution time |
| Comparison: naive full-tree vs adapter bootstrap | Quality of answers (separate eval) |

## Token estimation method (required)

Pick **one** method per benchmark series and keep it for all runs in that series. Document the choice on each `BENCHMARK_RUN`.

### Method A — chars/4 (default)

```text
tokens_est = ceil( total_utf8_char_count / 4 )
```

- Count characters after normalizing line endings to `\n` (optional but preferred for cross-OS runs).
- Include file content only; exclude path strings unless the path is pasted into the prompt.
- Good for mixed code + Markdown; slightly high for CJK, slightly low for dense English.

### Method B — words×1.3

```text
tokens_est = ceil( word_count * 1.3 )
```

- `word_count` = whitespace-separated tokens after the same newline normalization.
- Prefer when the corpus is mostly prose Markdown.

### Rules

- Do **not** mix A and B within one benchmark report.
- Sum per-file estimates; do not re-tokenize concatenated blobs differently unless noted.
- Optional helper: count chars/words with any stdlib script; do not call an LLM to estimate.

---

## Measures

### 1. Files read

| Field | Definition |
|-------|------------|
| **ID** | `files_read` |
| **Unit** | count (integer ≥ 0) |
| **Definition** | Number of distinct file paths whose contents were loaded into the agent working set for the measured phase |
| **How to count** | Unique absolute or repo-relative paths; re-reads of the same path count once |
| **Phase** | Bootstrap only unless the run notes “bootstrap + task” |
| **Exclusions** | Directory listings that do not open file bodies; binary assets not inlined |

### 2. Tokens estimated

| Field | Definition |
|-------|------------|
| **ID** | `tokens_est` |
| **Unit** | estimated tokens (integer ≥ 0) |
| **Definition** | Sum of Method A or B estimates over all files counted in `files_read` |
| **Method** | A (`chars/4`) or B (`words*1.3`) — see above |
| **Reporting** | Always state method: e.g. `tokens_est=4200 (chars/4)` |

### 3. Bootstrap time

| Field | Definition |
|-------|------------|
| **ID** | `bootstrap_ms` |
| **Unit** | milliseconds (integer ≥ 0) |
| **Definition** | Wall-clock from bootstrap start to ready (session readiness / first actionable context assembled) |
| **Clock** | Local machine wall clock; note OS and load if comparing machines |
| **Start** | First required-read (e.g. SYSTEM_MEMORY) or scripted bootstrap entry |
| **End** | Declared ready moment (SOP readiness emit or equivalent checkpoint) |
| **Exclusions** | Human think time after ready; unrelated tool waits after bootstrap |

### 4. Context reduction

| Field | Definition |
|-------|------------|
| **ID** | `context_reduction_pct` |
| **Unit** | percent (0–100, one decimal allowed) |
| **Definition** | How much smaller adapter bootstrap is vs a naive full-tree baseline on the **same** metric (prefer `tokens_est`, else `files_read`) |

```text
baseline = naive full-tree load (all in-scope project/vault files the agent would dump)
adapter  = project-adapter / ordered bootstrap load (PROJECT_CONTEXT_LOADING + memory + indexes)

context_reduction_pct = 100 * (1 - adapter / baseline)
```

| Rule | Detail |
|------|--------|
| Same corpus root | Baseline and adapter share the same repo/project root and in-scope globs |
| Same token method | Method A or B identical for both arms |
| Cap | If `adapter > baseline`, report negative reduction (regression) |
| Document | Record both raw `baseline_*` and `adapter_*` values, not only the percent |

**Naive full-tree (baseline):** count (and token-estimate) every text file under the declared root matching the run’s include globs, excluding `.git`, `node_modules`, and other listed ignore patterns.

**Adapter bootstrap:** count only files opened by the ordered load path (system/current/project memory, cited ADRs, indexes, task package) — not the whole tree.

### 5. Memory hits

| Field | Definition |
|-------|------------|
| **ID** | `memory_hits` |
| **Unit** | count (integer ≥ 0) |
| **Definition** | Number of distinct memory artifacts under `07_Memory/` (or declared memory roots) that were read and used as the primary fact source instead of re-deriving from raw project files |
| **Examples** | SYSTEM_MEMORY, CURRENT_STATE, PROJECT_MEMORY, DECISION_MEMORY, project memory slices |
| **Not a hit** | Opening a memory file that is empty/stub and then deep-reading the full source tree for the same facts (count as miss for that fact; still count the file under `files_read`) |

### 6. Index hits

| Field | Definition |
|-------|------------|
| **ID** | `index_hits` |
| **Unit** | count (integer ≥ 0) |
| **Definition** | Number of distinct index / TOC / catalog files used to locate targets **without** reading the full target body in the same phase |
| **Examples** | Generated indexes, folder READMEs used as maps, CONTEXT_PACKAGE indexes, ADR index lists |
| **Hit rule** | Index consulted → path selected → deep-read deferred or limited to selected paths |
| **Not a hit** | Reading an index and then opening every linked file in that phase |

---

## Derived (optional)

| ID | Formula |
|----|---------|
| `tokens_per_file` | `tokens_est / max(files_read, 1)` |
| `ms_per_file` | `bootstrap_ms / max(files_read, 1)` |

Report only if useful; not required for a valid run.

## Run identity

Every measurement must record:

- Date (ISO)
- AI-OS version / commit or tag if available
- Project or vault root
- Phase: `bootstrap` \| `bootstrap+task`
- Token method: `chars/4` \| `words*1.3`
- Arm: `baseline` \| `adapter`
- Operator / agent id (optional)

Use [../../11_Templates/metrics/BENCHMARK_RUN.md](../../11_Templates/metrics/BENCHMARK_RUN.md) per arm, then roll up in [../../11_Templates/CONTEXT_EFFICIENCY_BENCHMARK.md](../../11_Templates/CONTEXT_EFFICIENCY_BENCHMARK.md).
