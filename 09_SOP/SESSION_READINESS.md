# Session Readiness

Output standard for a short readiness report after bootstrap, before major work.

## When

After required reads + Git inspect + task context load. Skip for trivial one-file edits if already scoped.

## Format

```text
## Session readiness
- Phase / goal: {{FROM_CURRENT_STATE}}
- Branch: {{BRANCH}} | dirty: {{YES_NO_SUMMARY}}
- Task: {{TASK_TITLE_OR_LINK}}
- Loaded: SYSTEM_MEMORY, CURRENT_STATE{{, PROJECT, ADRs}}
- Write bounds: {{PATHS}}
- Do not touch: {{PATHS}}
- Blockers: {{NONE_OR_LIST}}
- Ready: yes | no
```

## Rules

- Keep under ~15 lines.
- Cite paths, not pasted file bodies.
- If Ready = no, stop and list blockers before editing.
