# v1.6.0-alpha.2 release readiness

## Version lock

| Item | Value |
|---|---|
| AI-OS | `v1.6.0-alpha.2` |
| Hermes tag | `v2026.8.3` |
| Hermes version | `0.20.0` |
| Hermes commit | `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` |
| MCP | `1.28.1` |
| Starlette | `1.3.1` |

The machine-readable source of truth is
[`scripts/hermes-install.lock.json`](../../scripts/hermes-install.lock.json).

## Worker validation evidence (Phase 1 — 2026-08-15)

Recorded by the implementation worker after re-running the alpha.2 suite.
This section is **not** Codex Pre-Deploy QA.

| Check | Command | Result |
|---|---|---|
| PowerShell syntax parse | `Parser.ParseFile` on `Install-HermesObsidianMemory.ps1` and `test-hermes-portable-install.ps1` | `PARSE_OK` |
| Python compile | `python -m py_compile` on IDE helper, sitecustomize, memory/skills/IDE tests | `PY_COMPILE_OK` |
| Portable installer plan | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-hermes-portable-install.ps1` | **53/53 PASS** (includes skills `--self-test`) |
| Cursor/VS Code schema tests | `python scripts/tests/test-hermes-ide-mcp.py` | **10/10 PASS** |
| Memory MCP protocol | `test-hermes-memory-mcp.py` with Hermes venv Python and native `HERMES_HOME` | PASS (`hermes_memory`, `hermes_session_search`) |
| Offline skills smoke | `test-hermes-skills-mcp.py --python <venv> --hermes-home <HERMES_HOME>` | PASS (`offline: true`, runner + server guard active, `deny_log: []`) |
| Network-deny negative test | skills `--self-test` deny probe | PASS; TCP + UDP `sendto` blocked; `sendmsg` not present on Windows |
| Diff whitespace | `git diff --check` | PASS (CRLF conversion warnings only) |
| Secret / host-path scan | added-line scan of the pack | no credentials or host paths |

Read-only host artifact inspection on 2026-08-15 (installer was **not** re-applied):

- Cursor local plugin version is `1.6.0-alpha.2`; worker rule is present
- Cursor `mcp.json` contains `hermes-memory`, `hermes-tools`, and `magnific`
- VS Code `mcp.json` contains `hermes-memory` and `hermes-tools`; Magnific is not present on this host
- VS Code worker instructions contain the unconditional `memory_candidates` rule
- Recognized legacy `~/.cursor/rules/hermes-worker.mdc` is absent
- Live `aios-integration.json` still records `v1.6.0-alpha.1` because Phase 1 did not re-run the installer

Prior 2026-08-14 live reapply and plugin-discovery evidence remains on this host.
Phase 1 did not independently re-execute those live writes.

## Required checks

### Completed worker/test evidence

- [x] PowerShell syntax parse
- [x] Python compile
- [x] MCP protocol initialization, tool listing and native memory read
- [x] Offline skills protocol smoke with runner + MCP server guard active and empty `deny.log`
- [x] Network-deny negative test with parent-seeded env scrubbed; TCP + UDP `sendto` blocked via Python socket guard (`sendmsg` when supported)
- [x] Skills `--self-test` invoked from portable test and installer path
- [x] Cursor plugin version derived from lock: `1.6.0-alpha.2`
- [x] Recognized AI-OS legacy rule deleted; customized `~/.cursor/rules/hermes-worker.mdc` preserved as `legacy-rule-preserved`
- [x] Cursor local plugin layout (`plugins/local/ai-os-hermes-worker`)
- [x] Cursor/VS Code MCP merge preserves Magnific and is compare-before-write
- [x] Portable installer plan test (53/53)
- [x] Cursor/VS Code schema, version, and legacy-rule tests (10/10)
- [x] Prior live Cursor/VS Code reapply (2026-08-14): second apply wrote nothing; backup count and mtime unchanged
- [x] Prior Cursor local plugin discovery (2026-08-14): `loadUserLocalPlugin ai-os-hermes-worker loaded`; `Plugins reload completed: 1 plugins loaded`

### Reserved gates

- [x] Codex Pre-Deploy QA (independent; final PASS 2026-08-15 on `3aca96b`)
- [ ] Release tag after merge

## Codex Pre-Deploy QA (2026-08-15)

Final independent Codex gate on CI-green head
`3aca96b91c8b0100897fed112f78659c81da29c3`.
That commit is the publication head for PR #4. It includes the lazy `mcp`
import so skills `--self-test` runs on GitHub `windows-latest`.

An earlier Codex pass on `0881a30` remains valid for the worker pack and is
superseded as the release head by `3aca96b`.

| Check | Result |
|---|---|
| Clean working tree | PASS |
| `git diff --check` | PASS |
| Portable installer plan | **53/53 PASS** |
| Cursor/VS Code schema tests | **10/10 PASS** |
| PR #4 CI | **success** ([run 31864700472](https://github.com/numtip/ai-operating-system/actions/runs/31864700472)) |
| Verdict | **PASSED** |

Product Owner approved completing publication (push / PR #4 / merge / tag).
Live installer re-run and integration-metadata refresh remain deferred.

## Portability boundary

This release supports Windows with Python `>=3.11,<3.14`, Git and PowerShell.
The installer makes no VPS, production, DNS or provider-account changes.
Credentials may be present in backed-up local config files; they are not
printed, exported, or committed.
The skills smoke network guard patches the Python stdlib `socket` module only.
Native extensions and child processes that bypass `sitecustomize` are outside
that guard.
