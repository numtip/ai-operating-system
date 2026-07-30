# Profile: Gemini

**profile_id:** `gemini`  
**Status:** Active (spec-only)  
**Phase:** 1

## Fit

- Latency-sensitive short tasks
- Preferred when `priority=latency`
- Broad context skim when `capability` includes `long_context` or `multimodal` (spec only)

## Prompt biases

- Ultra-short Goal + Files first
- Defer optional Context unless essential
- Prefer bullet constraints over paragraphs

## Capability affinity

`analysis`, `long_context`, `multimodal`, `writing`, `code`

## Compiler notes

- Default `model_class`: `long_context` when context paths are many; else `general`
- No multimodal payload handling in Phase 1
- No API integration in this profile
