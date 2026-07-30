# ADR-0003: Obsidian as Knowledge Interface

## Status

Accepted

## Date

2026-07-30

## Context

Humans need a Second Brain UX (links, graph, daily notes) over the Markdown vault. The interface must not become a second source of truth that bypasses Git.

## Decision

Obsidian is the human knowledge interface (Second Brain) over the Markdown vault. Git remains the source of truth; Obsidian edits the same files and does not replace version control.

## Consequences

- Productive browsing, linking, and note workflows for humans.
- Vault stays plain Markdown and Git-friendly.
- Users must commit Obsidian changes (see ADR-0002).
- Plugin choices should prefer vault-portable settings where practical.

## Alternatives

- **IDE/editor-only Markdown** — Rejected for Phase 1 human UX; weaker Second Brain affordances.
- **Obsidian as SoT (Sync-first)** — Rejected; Git is SoT per ADR-0002.

## Links

- [ADR-0002 GitHub Source of Truth](ADR-0002-github-source-of-truth.md)
- [README](README.md)
