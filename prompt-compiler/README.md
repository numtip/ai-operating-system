# Prompt Compiler Runtime (v1.4)

Executable MVP: compile **Project + Goal + Model Profile + Constraints** into Head Agent / Subagent prompts, a context manifest, and metrics — **without** LLM or network calls.

Specification (contracts): [`03_Architecture/prompt-compiler/`](../03_Architecture/prompt-compiler/)

## Usage

From repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compile-prompt.ps1 `
  -Project goffice2026 `
  -Goal "Audit production readiness without modifying the external repository." `
  -ModelProfile deepseek-v4-pro

# aliases / options
# -Model <id>          same as -ModelProfile
# -Constraints "read-only","no push"
# -OutputMode json|markdown|both
# -OutDir path/to/dir  write compile-result.json / .md
# -RepoRoot <path>     optional; defaults to AI-OS root
```

Equivalent conceptual CLI:

```text
compile --project goffice2026 --goal "..." --model deepseek-v4-pro
```

## Inputs

| Field | Required | Description |
|-------|----------|-------------|
| `project` | yes | Project id / `01_Projects/` folder |
| `goal` | yes | Non-empty measurable outcome |
| `model_profile` | yes | Profile id under `profiles/` |
| `constraints` | no | Hard rules (conflict detection applies) |
| `output_mode` | no | `json` \| `markdown` \| `both` (default both) |

Schema: [`schemas/input.schema.json`](schemas/input.schema.json)

## Outputs

- `head_agent_prompt` — compiled Head Agent brief
- `subagent_prompts[]` — bounded task prompts
- `context_manifest` — selected references only (no body copy)
- `metrics` — sizes, token estimate (chars/4), index hits, deterministic hash
- `errors` / `warnings`

Schema: [`schemas/output.schema.json`](schemas/output.schema.json)

## Model profiles

| id | File |
|----|------|
| `generic-reasoning` | `profiles/generic-reasoning.json` |
| `deepseek-v4-pro` | `profiles/deepseek-v4-pro.json` |
| `deepseek-v4-flash` | `profiles/deepseek-v4-flash.json` |
| `claude-coding` | `profiles/claude-coding.json` |
| `cursor-coding` | `profiles/cursor-coding.json` |

Profiles define execution style only — not project instructions.

## Flow

```text
User Intent → Task Normalization → Project Adapter Lookup
→ Context Selection → Model Profile Selection → Prompt Compilation
→ Validation → Metrics
```

## Tests

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File prompt-compiler/tests/run-tests.ps1
```

## V1.4 — Context Optimizer + Prompt Quality Gate

- **Deterministic ranking** — after selection, `Optimize-CompilerContext` scores every ref with constant weights (required 1000, bootstrap 800, adapter 700, project/memory 600, index 500, knowledge/ADR index 400 + 10 per goal-token hit, other 300). Same inputs → identical selection and hash.
- **Budget enforcement** — optional refs are kept in score order up to `max_files` (default: `min(profile.context_limit_policy.max_context_refs, 10)`; `max_tokens` default 0 = off). Both are overridable via an optional `context_budget` block in a model profile. Over-budget refs are reported in `metrics.optimization.rejected`.
- **Duplicate / low-value elimination** — paths that collide after case/slash normalization are rejected (`duplicate_path`), and optional `goal_match` refs whose own path contains no goal token are rejected (`low_value_goal_match`).
- **Mandatory-context preservation** — required refs are never dropped; if required refs alone exceed the budget, the overflow is allowed and only optional refs are trimmed.
- **Prompt quality gate** — `Assert-PromptQualityGate` runs after validation and fails the compile with actionable `quality_gate:` errors for: missing subagent sections (`Assigned objective`, `Forbidden scope`, `Handoff format`, `Output limit`), prohibited-action or hardcoded-secret instructions outside Forbidden sections, network instructions under a `no-network` tool policy, head prompt > 1200 words, or subagent prompt > 400 words. `read-only-first` profiles get a soft `quality_gate_warn:` check.
- **New metrics** — `metrics.optimization` (files selected/rejected, rejected list, budgets, required count), `metrics.quality_gate` (error/warning counts), `metrics.context_files_rejected`, and `compiler_metadata.optimizer_version`.

## Non-goals

- Provider API calls
- Hermes install / orchestration
- Copying external project documentation into the vault
