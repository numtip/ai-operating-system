# Release Readiness — v1.5.0-alpha.1

| Check | Result | Evidence |
|-------|--------|----------|
| Gate script present | PASS | [`scripts/check-bootstrap.ps1`](../../scripts/check-bootstrap.ps1) |
| Manifest v1.2 parses | PASS | [`09_SOP/bootstrap-manifest.json`](../../09_SOP/bootstrap-manifest.json) |
| Gate tests | 33/33 PASS | [`scripts/tests/test-check-bootstrap.ps1`](../../scripts/tests/test-check-bootstrap.ps1) |
| Structure validate | PASS | `scripts/validate-structure.ps1` |
| ADR-0012 Accepted + indexed | PASS | [ADR-0012](../../04_ADR/ADR-0012-automated-bootstrap-gate.md), `12_Indexes/adr_index.json` |
| Readiness standard | PASS | [`09_SOP/SESSION_READINESS.md`](../../09_SOP/SESSION_READINESS.md) |
| SOP Step 0 documents gate | PASS | [`09_SOP/AGENT_BOOTSTRAP.md`](../../09_SOP/AGENT_BOOTSTRAP.md) |
| Changelog entry | PASS | [CHANGELOG.md](../../CHANGELOG.md) (`[v1.5.0-alpha.1]`) |
| CI hook | PASS | [`.github/workflows/bootstrap-gate.yml`](../../.github/workflows/bootstrap-gate.yml) |
| No Hermes / secrets | PASS | scope of this pack |

## Residual risk

- Tag / push deferred until human approval.
- CI runs after push/PR; local SOP Step 0 remains required before agent work.

## Related

- [README.md](README.md) · [RELEASE_NOTES.md](RELEASE_NOTES.md)
