# Profile: DeepSeek

**profile_id:** `deepseek`  
**Status:** Active (spec-only)  
**Phase:** 1

## Fit

- Cost-sensitive drafting and coding
- Preferred when `priority=cost`
- Spec and refactor tasks with tight Output Format

## Prompt biases

- Maximize constraint density; minimize narrative
- Strong “Return ONLY” framing
- Short examples over long explanations

## Capability affinity

`code`, `writing`, `analysis`

## Compiler notes

- Default `model_class`: `code`
- Favor aggressive length trim under SHORT_PROMPT_STANDARD
- No API integration in this profile
