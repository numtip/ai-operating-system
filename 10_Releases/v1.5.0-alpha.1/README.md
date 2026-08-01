# v1.5.0-alpha.1

Agent Bootstrap Automation — alpha.

## Contents

| Artifact | Path |
|----------|------|
| Gate checker | [`scripts/check-bootstrap.ps1`](../../scripts/check-bootstrap.ps1) |
| Gate tests | [`scripts/tests/test-check-bootstrap.ps1`](../../scripts/tests/test-check-bootstrap.ps1) (33 PASS) |
| Manifest | [`09_SOP/bootstrap-manifest.json`](../../09_SOP/bootstrap-manifest.json) (v1.2) |
| Readiness standard | [`09_SOP/SESSION_READINESS.md`](../../09_SOP/SESSION_READINESS.md) |
| SOP / checklist | [`09_SOP/AGENT_BOOTSTRAP.md`](../../09_SOP/AGENT_BOOTSTRAP.md), [`09_SOP/AGENT_BOOTSTRAP_CHECKLIST.md`](../../09_SOP/AGENT_BOOTSTRAP_CHECKLIST.md) |
| ADR | [`04_ADR/ADR-0012-automated-bootstrap-gate.md`](../../04_ADR/ADR-0012-automated-bootstrap-gate.md) |
| Changelog | [`CHANGELOG.md`](../../CHANGELOG.md) (`[v1.5.0-alpha.1]`) |
| CI workflow | [`.github/workflows/bootstrap-gate.yml`](../../.github/workflows/bootstrap-gate.yml) |
| Tag | `v1.5.0-alpha.1` @ `b995f19` |
| Verified CI | [run #1 success](https://github.com/numtip/ai-operating-system/actions/runs/30707493725) — detail in [RELEASE_READINESS.md](RELEASE_READINESS.md) |
| Notes | [RELEASE_NOTES.md](RELEASE_NOTES.md) · [RELEASE_READINESS.md](RELEASE_READINESS.md) |

## Verify

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-bootstrap.ps1 -ProjectName goffice2026 -Json
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-check-bootstrap.ps1
```

## Constraints

- Local PowerShell gate only — no LLM, Hermes, or network
- Further tags / GitHub Release assets still need human approval when changing history
