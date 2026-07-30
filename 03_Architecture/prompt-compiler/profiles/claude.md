# Profile: Claude

**profile_id:** `claude`  
**Status:** Active (spec-only)  
**Phase:** 1

## Fit

- High-quality specification and architecture writing
- Preferred when `priority=quality`
- Multi-constraint tasks needing careful scope obedience

## Prompt biases

- Emphasize do-not-touch and scope.out early
- Prefer precise file bounds
- Allow slightly denser Constraints if still within word cap

## Capability affinity

`writing`, `code`, `analysis`, `long_context`, `planning`

## Compiler notes

- Default `model_class`: `general`
- Good default for Head→subagent vault edits
- No API integration in this profile
