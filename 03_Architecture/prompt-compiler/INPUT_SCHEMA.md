# Input Schema

Canonical fields accepted by the Prompt Compiler. All inputs are declarative; no runtime resolution.

## Required

| Field | Type | Description |
|-------|------|-------------|
| `goal` | string | Single measurable outcome |
| `scope.in` | string[] | Explicitly allowed work |
| `scope.out` | string[] | Explicitly forbidden work |
| `files.write` | path[] | Paths the agent may create/edit |
| `constraints` | string[] | Hard rules (phase, no-API, no-touch paths, etc.) |
| `validation` | string[] | Pass/fail checks for the deliverable |
| `output_format` | string | Exact return shape the agent must use |

## Optional

| Field | Type | Description |
|-------|------|-------------|
| `files.read` | path[] | Paths to read for context |
| `files.do_not_touch` | path[] | Hard deny list |
| `context` | string | Minimal background (prefer links over prose) |
| `routing.profile` | enum | `gpt` \| `deepseek` \| `claude` \| `gemini` \| `hermes` |
| `routing.priority` | enum | `cost` \| `quality` \| `latency` \| `balanced` |
| `routing.capability` | string[] | Needed traits (e.g. `code`, `long_context`, `tool_use`) |
| `budget.max_tokens_prompt` | integer | Soft cap for compiled prompt size |
| `budget.max_sections` | integer | Soft cap for section count |
| `phase` | string | e.g. `Phase 1` — used to suppress deferred profiles |

## Validation rules (input)

1. `goal` must be one sentence, outcome-focused.
2. `files.write` must be non-empty when the task mutates the vault.
3. If `routing.profile` = `hermes`, compiler MUST mark output as **deferred** and MUST NOT imply live execution.
4. `constraints` MUST restate any global bans relevant to the task (e.g. no API calls).
5. Unknown fields are rejected; do not silently ignore.

## Example (illustrative)

```yaml
goal: "Create Prompt Compiler specs under 03_Architecture/prompt-compiler/"
scope:
  in: ["prompt-compiler specs", "SUBAGENT_TASK_PROMPT template"]
  out: ["API integrations", "ADR edits"]
files:
  write: ["03_Architecture/prompt-compiler/", "11_Templates/SUBAGENT_TASK_PROMPT.md"]
  do_not_touch: ["04_ADR/", "scripts/"]
constraints:
  - "Spec-only; no API calls"
validation:
  - "All listed files exist"
  - "Each file is concise and spec-only"
output_format: |
  Return ONLY: files created, one-line purpose each, blockers.
routing:
  profile: claude
  priority: balanced
```
