# Decision Memory

Index of Architecture Decision Records. Canonical ADR text lives in `04_ADR/`; this file is the memory pointer only.

| ID | Title | Link |
|----|-------|------|
| ADR-0001 | Local-first development | [ADR-0001](../04_ADR/ADR-0001-local-first-development.md) |
| ADR-0002 | GitHub as source of truth | [ADR-0002](../04_ADR/ADR-0002-github-source-of-truth.md) |
| ADR-0003 | Obsidian as knowledge interface | [ADR-0003](../04_ADR/ADR-0003-obsidian-knowledge-interface.md) |
| ADR-0004 | Hermes deferred to Phase 2 | [ADR-0004](../04_ADR/ADR-0004-hermes-deferred-phase-2.md) |
| ADR-0005 | Context Engine as core layer | [ADR-0005](../04_ADR/ADR-0005-context-engine-core-layer.md) |
| ADR-0006 | File-based indexes before vector | [ADR-0006](../04_ADR/ADR-0006-file-based-indexes-before-vector.md) |
| ADR-0007 | Prompt Compiler specification-first | [ADR-0007](../04_ADR/ADR-0007-prompt-compiler-specification-first.md) |
| ADR-0008 | Memory compression threshold | [ADR-0008](../04_ADR/ADR-0008-memory-compression-threshold.md) |
| ADR-0009 | Agent bootstrap mandatory | [ADR-0009](../04_ADR/ADR-0009-agent-bootstrap-mandatory.md) |
| ADR-0010 | Project Adapter for external pilots | [ADR-0010](../04_ADR/ADR-0010-project-adapter-external-pilots.md) |

## Rules

- New decision → write ADR under `04_ADR/`, then add a row here
- Do not duplicate ADR body in Memory
- Session that adds an ADR must update this index ([SESSION_CLOSE](SESSION_CLOSE.md))
- Machine index: [adr_index.json](../12_Indexes/adr_index.json)

## Related

- [SYSTEM_MEMORY](SYSTEM_MEMORY.md) · [CURRENT_STATE](CURRENT_STATE.md) · [ROADMAP](../03_Architecture/ROADMAP.md)
