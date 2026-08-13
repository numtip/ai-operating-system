# Agent Bootstrap

Canonical session-start protocol for AI-OS v1.1. Spec only — no runtime service.

## Steps (in order)

0. **Automated gate** — Run [`scripts/check-bootstrap.ps1`](../scripts/check-bootstrap.ps1) before executing. FAIL gates block execution; WARN proceeds only when documented. Aligns with the [SESSION_READINESS.md](SESSION_READINESS.md) standard (ADR-0012).
1. **Read shared agent memory** — Call `hermes_memory` with `action=read`, `target=all`; use only task-relevant entries. If the tool is unavailable in a newly configured Codex client, restart Codex instead of creating another memory store.
2. **Read system memory** — `07_Memory/SYSTEM_MEMORY.md` (required).
3. **Read current state** — `07_Memory/CURRENT_STATE.md` (required).
4. **Inspect Git** — `git status`; `git log -5 --oneline`. Note branch, dirty paths, recent commits. Do not commit/push unless Head Agent owns it and human approved where required.
5. **Load task context** — Search `hermes_session_search` narrowly when prior work may answer the task, then follow [../03_Architecture/PROJECT_CONTEXT_LOADING.md](../03_Architecture/PROJECT_CONTEXT_LOADING.md): project memory → relevant ADRs → task/context package.
6. **Execute and close** — Change only assigned paths; validate narrowly; save only durable facts to Hermes memory; close per [../07_Memory/SESSION_CLOSE.md](../07_Memory/SESSION_CLOSE.md).

## Related

- Checklist: [AGENT_BOOTSTRAP_CHECKLIST.md](AGENT_BOOTSTRAP_CHECKLIST.md)
- Manifest: [bootstrap-manifest.json](bootstrap-manifest.json)
- Readiness standard: [SESSION_READINESS.md](SESSION_READINESS.md)
- ADR: [ADR-0012](../04_ADR/ADR-0012-automated-bootstrap-gate.md)
- Release: [10_Releases/v1.6.0-alpha.1/](../10_Releases/v1.6.0-alpha.1/)
- Changelog: [CHANGELOG.md](../CHANGELOG.md) (`[v1.6.0-alpha.1]`)
- CI: [../.github/workflows/bootstrap-gate.yml](../.github/workflows/bootstrap-gate.yml)
- Context Engine: [../03_Architecture/CONTEXT_ENGINE.md](../03_Architecture/CONTEXT_ENGINE.md)
- Memory bootstrap (detail): [../07_Memory/SESSION_BOOTSTRAP.md](../07_Memory/SESSION_BOOTSTRAP.md)
