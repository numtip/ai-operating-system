# v1.6.0-alpha.1 release readiness

## Version lock

| Item | Value |
|---|---|
| AI-OS | `v1.6.0-alpha.1` |
| Hermes tag | `v2026.8.3` |
| Hermes version | `0.20.0` |
| Hermes commit | `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` |
| MCP | `1.28.1` |
| Starlette | `1.3.1` |

The machine-readable source of truth is
[`scripts/hermes-install.lock.json`](../../scripts/hermes-install.lock.json).

## Required checks

- [x] PowerShell syntax parse
- [x] Python compile
- [x] MCP protocol initialization, tool listing and native memory read
- [x] Bundled `SKILL.md` sync — 71 native skills seeded; Hermes Agent and Obsidian skills verified through `skills_list` / `skill_view`
- [x] Portable installer plan test (24/24)
- [x] Live end-to-end reinstall using the published installer
- [x] AI-OS structure and index validation
- [x] Bootstrap gate and 33 bootstrap assertions
- [x] Cross-repo Hermes project lookup without target-repository changes
- [x] Obsidian process opened against native Hermes home on the validation host
- [x] GitHub Actions on PR #4 — `check-bootstrap + tests` PASS ([run 31728693832](https://github.com/numtip/ai-operating-system/actions/runs/31728693832))
- [ ] Release tag after merge

## Portability boundary

This release supports Windows with Python `>=3.11,<3.14`, Git and PowerShell.
Obsidian can be installed through `winget` when `-InstallObsidian` is supplied.
The installer makes no VPS, production, DNS or provider-account changes.
