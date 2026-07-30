# Project Bootstrap

Human/agent SOP for **project-scoped** bootstrap (AI-OS v1.2). Spec-only wrapper around the bootstrap runtime. Complements session-start protocol in [AGENT_BOOTSTRAP.md](AGENT_BOOTSTRAP.md).

## When to use

- Starting work on a named project under `01_Projects/`
- Assembling an ordered context package before task execution
- Dry-running load cost via `scripts/simulate-bootstrap.ps1`

## When to use AGENT_BOOTSTRAP instead

Use [AGENT_BOOTSTRAP.md](AGENT_BOOTSTRAP.md) for **every session start** (system memory → current state → git inspect). This SOP adds the **project resolution** layer on top of that baseline.

## Steps

1. **Session baseline** — Follow [AGENT_BOOTSTRAP.md](AGENT_BOOTSTRAP.md) steps 1–2 (read `SYSTEM_MEMORY.md`, `CURRENT_STATE.md`).
2. **Read indexes** — Open `12_Indexes/project_index.json`. Resolve the project by `id`, path segment, or title. Do not walk `01_Projects/` until the index is checked.
3. **Locate canonical files** — Confirm `01_Projects/<name>/`. Note presence of `ADAPTER.md`, `README.md`. Do not follow external adapter targets.
4. **Load minimum context** — Per [../03_Architecture/bootstrap-runtime/SPEC.md](../03_Architecture/bootstrap-runtime/SPEC.md) step 3. Cap at 6 file bodies.
5. **Emit package** — Fill [../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md](../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md). Produce bootstrap summary per [../03_Architecture/bootstrap-runtime/OUTPUT_SCHEMA.md](../03_Architecture/bootstrap-runtime/OUTPUT_SCHEMA.md).
6. **Continue session** — Resume [AGENT_BOOTSTRAP.md](AGENT_BOOTSTRAP.md) from git inspect → execute. Keep write bounds tight.

## Simulation

```powershell
pwsh -File scripts/simulate-bootstrap.ps1 -ProjectName <name>
```

- Stdout always receives the summary.
- If `ADAPTER.md` exists, also writes `01_Projects/<name>/last-bootstrap-simulation.md`.
- Does not call LLMs or modify external trees.

## Related

- Runtime overview: [../03_Architecture/bootstrap-runtime/README.md](../03_Architecture/bootstrap-runtime/README.md)
- Context loading: [../03_Architecture/PROJECT_CONTEXT_LOADING.md](../03_Architecture/PROJECT_CONTEXT_LOADING.md)
- Checklist (session): [AGENT_BOOTSTRAP_CHECKLIST.md](AGENT_BOOTSTRAP_CHECKLIST.md)
