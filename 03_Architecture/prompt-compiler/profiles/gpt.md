# Profile: GPT

**profile_id:** `gpt`  
**Status:** Active (spec-only)  
**Phase:** 1

## Fit

- General coding and structured writing
- Balanced quality / latency when `priority=balanced` or `latency`
- Tasks with clear sectioned briefs

## Prompt biases

- Keep instructions explicit and ordered
- Prefer checklist validation
- Avoid persona padding

## Capability affinity

`code`, `writing`, `analysis`, `tool_use`, `planning`

## Compiler notes

- Default `model_class`: `general`
- Do not emit vendor model IDs in Phase 1 specs
- No API integration in this profile
