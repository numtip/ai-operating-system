# Subagent Task Prompt

Use this template when the Head Agent compiles a task for a subagent.  
Aligns with Prompt Compiler input schema. Keep short.

---

## Goal
{{ONE_SENTENCE_MEASURABLE_GOAL}}

## Scope
**In**
- {{IN_SCOPE}}

**Out**
- {{OUT_OF_SCOPE}}

## Files
**Read**
- `{{READ_PATH}}`

**Write only**
- `{{WRITE_PATH}}`

**Do not touch**
- `{{DENY_PATH}}`

## Constraints
- {{HARD_RULE}}
- Spec-only / no API calls unless this task explicitly allows them.
- Do not commit or push unless explicitly asked.

## Validation
- [ ] {{CHECK}}
- [ ] Output matches Output Format exactly

## Output Format
Return ONLY:
- {{DELIVERABLE_1}}
- {{DELIVERABLE_2}}
- Blockers

## Context (optional)
{{LINKS_OR_MINIMAL_NOTES}}

---

## Routing (Head-only; omit from subagent paste if unused)
```yaml
routing:
  profile: {{gpt|deepseek|claude|gemini|hermes}}
  priority: {{cost|quality|latency|balanced}}
  capability: [{{token}}]
```
