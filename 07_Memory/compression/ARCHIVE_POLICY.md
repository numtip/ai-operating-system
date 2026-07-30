# Archive Policy

How to retain or retire session files after compression.

## Eligibility

A session file may be archived only when:

1. It is indexed in `SESSION_INDEX.md`
2. Its outcomes appear in a compression summary (or living memory)
3. No open decision depends solely on that file’s unreproduced detail

## Actions

| Action | When | Effect |
|--------|------|--------|
| Keep active | Default / under threshold | File stays under `07_Memory/sessions/YYYY/` |
| Archive | After successful compression | Move to `07_Memory/sessions/archive/YYYY/` (create as needed); update `SESSION_INDEX` paths |
| Delete | Rare; human approval only | Only if content is fully superseded and non-auditable noise |

## Rules

- Never archive or delete the sole copy of an untraced decision.
- Prefer move-to-archive over delete.
- Update indexes and links in the same change set as the move.
- No secrets in archives. Redact before moving if needed.
- Compression summaries remain under `07_Memory/compression/` or linked from living memory — not only in chat.
