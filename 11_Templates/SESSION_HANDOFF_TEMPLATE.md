# Session Handoff: {{SESSION_ID}} — {{DATE}}

## Baseline
- Branch: `{{BRANCH}}`
- Commit: `{{SHA}}`
- Focus: {{WHAT_SESSION_STARTED_FROM}}

## Changes
- {{FILE_OR_AREA}}: {{WHAT_CHANGED}}

## Validation
- [ ] {{CHECK}}
- Structure: `pwsh -File scripts/validate-structure.ps1` → {{PASS|FAIL}}

## Decisions
- {{DECISION}} — rationale: {{WHY}}

## Memory Updates
- [ ] `CURRENT_STATE.md`
- [ ] `SESSION_INDEX.md`
- [ ] `DECISION_MEMORY.md` (if decisions made)
- Notes: {{WHAT_WAS_WRITTEN}}

## Git Status
```
{{git status --short}}
```
Uncommitted: {{YES|NO}} — Do not commit unless requested.

## Next Action
1. {{IMMEDIATE_NEXT_STEP}}
