# Prompt Compiler Runtime (v1.3)

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

## Non-goals

- Provider API calls
- Hermes install / orchestration
- Copying external project documentation into the vault
