# Output Contract

Required shape of a compiled Prompt Compiler result. Spec-only; no provider payload serialization beyond named fields.

## Top-level object

| Field | Required | Description |
|-------|----------|-------------|
| `prompt` | yes | Final short prompt text (see SHORT_PROMPT_STANDARD) |
| `routing` | yes | Declared routing block (see ROUTING.md) |
| `profile_id` | yes | One of: `gpt`, `deepseek`, `claude`, `gemini`, `hermes` |
| `deferred` | yes | `true` if profile/runtime is Phase-deferred |
| `checklist` | yes | Validation items the consumer must satisfy |
| `warnings` | no | Non-fatal issues (e.g. truncated context) |
| `errors` | no | Fatal compile failures; if present, `prompt` MUST be empty |

## `prompt` requirements

1. Must include: Goal, Scope, Files, Constraints, Validation, Output Format.
2. Must obey `SHORT_PROMPT_STANDARD.md`.
3. Must not contain API keys, endpoints, or live invoke instructions.
4. Must not invent write paths outside `files.write`.

## `routing` requirements

1. Must be complete per ROUTING.md required fields.
2. Must not include secrets or connection strings.
3. `profile_id` and `routing.profile` MUST match.

## Success vs failure

| Condition | Result |
|-----------|--------|
| Input valid, profile active | `errors` absent; `deferred=false`; `prompt` non-empty |
| Input valid, profile Hermes | `errors` absent; `deferred=true`; `prompt` may be a Phase-2 placeholder brief |
| Input invalid | `errors` non-empty; `prompt` empty; do not route |

## Consumer obligations

- Treat this contract as read-only specification until a runtime implements it.
- Do not call models from the compiler package.
- Validate returned agent work against `checklist`, not against this contract alone.
