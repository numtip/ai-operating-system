# ADR-0002: GitHub as Source of Truth

## Status

Accepted

## Date

2026-07-30

## Context

Knowledge lives as Markdown and must remain versioned, reviewable, and recoverable. Local Obsidian edits alone can diverge, get lost, or lack history. A single canonical remote is required.

## Decision

The GitHub repository https://github.com/numtip/ai-operating-system is the source of truth for versioned knowledge. Obsidian (and other local) edits must be committed to Git and pushed so the remote reflects the vault.

## Consequences

- History, review, and backup via Git/GitHub.
- Local vault and remote stay aligned through commit discipline.
- Contributors must treat uncommitted Obsidian changes as draft until committed.
- Access and collaboration follow GitHub permissions.

## Alternatives

- **Obsidian Sync / cloud vault as SoT** — Rejected; weaker versioning and review than Git.
- **Local-only Git without remote** — Rejected; no shared backup or collaboration SoT.

## Links

- [ADR-0003 Obsidian Knowledge Interface](ADR-0003-obsidian-knowledge-interface.md)
- [README](README.md)
