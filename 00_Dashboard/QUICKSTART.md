# Agent Quickstart

Bootstrap every session in this order. Do not load the whole vault.

1. **Rules** — Read [../07_Memory/OPERATING_RULES.md](../07_Memory/OPERATING_RULES.md).
2. **System facts** — Read [../07_Memory/SYSTEM_MEMORY.md](../07_Memory/SYSTEM_MEMORY.md).
3. **Live state** — Read [../07_Memory/CURRENT_STATE.md](../07_Memory/CURRENT_STATE.md).
4. **Scope** — Open only relevant project memory under `07_Memory/projects/` and active tasks under `01_Projects/`.
5. **Decisions** — Read ADRs in [../04_ADR/](../04_ADR/) that match the task (prefer index/summary first).
6. **Templates** — Use [../11_Templates/](../11_Templates/) when creating projects, SOPs, handoffs, or releases.
7. **Work** — Inspect Git status, change only assigned paths, validate narrowly.
8. **Close** — Update `CURRENT_STATE.md`, `SESSION_INDEX.md`, and a session note under `07_Memory/sessions/YYYY/`. Record major decisions as ADRs.

## Defaults

- Memory before history; summaries before raw notes
- One Head Agent owns commits and final report
- Human approval for deploy, secrets, destructive actions
- No Hermes / VPS / secrets in Phase 1

See [HOME.md](HOME.md) for the dashboard map.
