# Release Readiness — v1.5.0-alpha.1

| Check | Result | Evidence |
|-------|--------|----------|
| Gate script present | PASS | [`scripts/check-bootstrap.ps1`](../../scripts/check-bootstrap.ps1) |
| Manifest v1.2 parses | PASS | [`09_SOP/bootstrap-manifest.json`](../../09_SOP/bootstrap-manifest.json) |
| Gate tests (local) | 33/33 PASS | [`scripts/tests/test-check-bootstrap.ps1`](../../scripts/tests/test-check-bootstrap.ps1) |
| Structure validate | PASS | `scripts/validate-structure.ps1` |
| ADR-0012 Accepted + indexed | PASS | [ADR-0012](../../04_ADR/ADR-0012-automated-bootstrap-gate.md), `12_Indexes/adr_index.json` |
| Readiness standard | PASS | [`09_SOP/SESSION_READINESS.md`](../../09_SOP/SESSION_READINESS.md) |
| SOP Step 0 documents gate | PASS | [`09_SOP/AGENT_BOOTSTRAP.md`](../../09_SOP/AGENT_BOOTSTRAP.md) |
| Changelog entry | PASS | [CHANGELOG.md](../../CHANGELOG.md) (`[v1.5.0-alpha.1]`) |
| CI workflow present | PASS | [`.github/workflows/bootstrap-gate.yml`](../../.github/workflows/bootstrap-gate.yml) |
| CI run (remote) | PASS | see [Verified CI](#verified-ci) |
| Git tag | PASS | `v1.5.0-alpha.1` → `b995f19` (pushed to origin) |
| No Hermes / secrets | PASS | scope of this pack |

## Verified CI

Source: public GitHub Actions API (repo is public; `gh` CLI not authenticated in this environment).

| Field | Value |
|-------|--------|
| Workflow | Bootstrap Gate (`.github/workflows/bootstrap-gate.yml`) |
| Run | [#1](https://github.com/numtip/ai-operating-system/actions/runs/30707493725) |
| Head SHA | `b995f1982290e3d5be2f3db63c7ce41c3aec8db1` |
| Event | `push` to `main` |
| Status / conclusion | `completed` / **`success`** |
| Job | `check-bootstrap + tests` on `windows-latest` — **success** |
| Steps | Checkout, Bootstrap gate (default), Bootstrap gate (goffice2026 pilot), Bootstrap gate unit tests — all **success** |
| Started / completed (UTC) | 2026-08-01T16:08:59Z → 2026-08-01T16:09:27Z |

## Residual risk

- Local SOP Step 0 remains required before agent work (CI does not replace session bootstrap).
- `gh` CLI not logged in here — run status confirmed via REST API, not `gh run view` / job logs download.
- GitHub Release UI asset (optional) not created; tag + pack docs only.

## Related

- [README.md](README.md) · [RELEASE_NOTES.md](RELEASE_NOTES.md)
