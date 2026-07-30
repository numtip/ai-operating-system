# Routing

Declarative model-routing fields for the Prompt Compiler. Selection is logical only—no API binding.

## Required fields

| Field | Type | Description |
|-------|------|-------------|
| `profile` | enum | `gpt` \| `deepseek` \| `claude` \| `gemini` \| `hermes` |
| `priority` | enum | `cost` \| `quality` \| `latency` \| `balanced` |
| `capability` | string[] | Traits the task needs |

## Optional fields

| Field | Type | Description |
|-------|------|-------------|
| `model_class` | string | Logical class only (e.g. `general`, `code`, `long_context`) — not a vendor model ID |
| `max_context_hint` | integer | Approximate context need in tokens (hint, not a hard API param) |
| `tool_use` | boolean | Whether the task expects tool/function calling semantics |
| `reason` | string | One-line human rationale for the chosen profile |

## Capability vocabulary (canonical)

Use only these tokens unless extended by a later ADR:

- `code`
- `writing`
- `analysis`
- `long_context`
- `tool_use`
- `multimodal`
- `planning`

## Routing rules (Phase 1)

1. Prefer an active profile (`gpt`, `deepseek`, `claude`, `gemini`).
2. If `profile=hermes` → set `deferred=true`; do not imply execution.
3. Map `priority`:
   - `cost` → prefer DeepSeek profile notes
   - `quality` → prefer Claude or GPT profile notes
   - `latency` → prefer Gemini or GPT profile notes
   - `balanced` → any active profile with matching `capability`
4. Never emit vendor API model strings as required fields.
5. Never emit auth, base URLs, or region endpoints.

## Output fragment (routing block)

```yaml
routing:
  profile: claude
  priority: balanced
  capability: [code, writing]
  model_class: general
  tool_use: false
  reason: "Spec drafting; quality over latency"
```
