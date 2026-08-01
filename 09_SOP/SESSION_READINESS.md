# Session Readiness

Output standard for a short readiness report after bootstrap, before major work. The automated gate ([`scripts/check-bootstrap.ps1`](../scripts/check-bootstrap.ps1)) verifies this artifact path exists and emits its own PASS/WARN/FAIL evidence (text or JSON). Agents should still emit a readiness report in this shape when documenting session start.

## When

After required reads + Git inspect + task context load. Skip for trivial one-file edits if already scoped.

## Report fields

| Field | Type | Meaning |
|-------|------|---------|
| `status` | `ready` \| `degraded` \| `not_ready` | Overall verdict |
| `gates` | `[{name, status}]` | Per-gate `status`: `pass` \| `warn` \| `fail` |
| `evidence` | object | Paths read; git branch + dirty summary |
| `estimated_context_set` | list | Items loaded (memory, ADRs, task package) |
| `blockers` | list | Reasons blocking execution; empty if none |

## Example

```json
{
  "status": "degraded",
  "gates": [
    { "name": "required_reads_present", "status": "pass" },
    { "name": "git_inspected", "status": "pass" },
    { "name": "scope_bounds_clear", "status": "warn" },
    { "name": "validation_planned", "status": "pass" }
  ],
  "evidence": {
    "paths_read": ["07_Memory/SYSTEM_MEMORY.md", "07_Memory/CURRENT_STATE.md"],
    "branch": "main",
    "dirty": false
  },
  "estimated_context_set": ["SYSTEM_MEMORY", "CURRENT_STATE"],
  "blockers": []
}
```

## Rules

- Human summary under ~15 lines; JSON under ~40 lines.
- Cite paths, not pasted file bodies.
- Any gate `fail` → `status: not_ready`: blocks execution until blockers are resolved and gates re-run.
- Any gate `warn` → `status: degraded`: proceeds only with documented WARN.
- All gates `pass` → `status: ready`.

## Related

- Gate: [`scripts/check-bootstrap.ps1`](../scripts/check-bootstrap.ps1)
- Manifest: [bootstrap-manifest.json](bootstrap-manifest.json)
- SOP: [AGENT_BOOTSTRAP.md](AGENT_BOOTSTRAP.md)
- ADR: [ADR-0012](../04_ADR/ADR-0012-automated-bootstrap-gate.md)
- Changelog: [CHANGELOG.md](../CHANGELOG.md) (`[v1.5.0-alpha.1]`)
- Release: [10_Releases/v1.5.0-alpha.1/](../10_Releases/v1.5.0-alpha.1/)
