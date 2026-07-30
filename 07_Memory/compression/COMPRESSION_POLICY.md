# Compression Policy

When session volume grows, compress raw handoffs into durable summaries. Do not delete until archive policy allows.

## Triggers

- Session count under `07_Memory/sessions` reaches [THRESHOLD.json](THRESHOLD.json) (`session_count_threshold`, default **25**)
- Or human / Head Agent requests compression after a milestone

Check: `pwsh -File scripts/check-session-threshold.ps1`

## What to produce

| Artifact | Template | Purpose |
|----------|----------|---------|
| Session rollup | [SESSION_SUMMARY](../../11_Templates/SESSION_SUMMARY.md) | Closed sessions → concise outcomes |
| Executive memory | [EXECUTIVE_MEMORY_SUMMARY](../../11_Templates/EXECUTIVE_MEMORY_SUMMARY.md) | Cross-session state for leadership / bootstrap |
| Open decisions | [OPEN_DECISIONS_SUMMARY](../../11_Templates/OPEN_DECISIONS_SUMMARY.md) | Unresolved choices still blocking work |
| Lessons | [LESSONS_LEARNED_SUMMARY](../../11_Templates/LESSONS_LEARNED_SUMMARY.md) | Reusable failures and fixes |

## Rules

- Summarize; do not invent facts not present in sessions or memory files.
- Keep links to source session paths.
- Prefer updating living memory (`CURRENT_STATE`, `DECISION_MEMORY`, project memory) over duplicating prose.
- Human-readable markdown only. No DB, no binary blobs, no secrets.
- After compression, follow [ARCHIVE_POLICY](ARCHIVE_POLICY.md) for raw sessions.
