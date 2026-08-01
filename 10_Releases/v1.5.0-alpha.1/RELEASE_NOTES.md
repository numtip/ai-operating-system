# Release Notes — v1.5.0-alpha.1

**Tag:** `v1.5.0-alpha.1`  
**Date:** 2026-08-01  
**Theme:** Machine-enforce agent bootstrap before work starts.

## Highlights

1. **Automated Bootstrap Gate** — [`scripts/check-bootstrap.ps1`](../../scripts/check-bootstrap.ps1) validates manifest, required reads, git inspect, and optional project readiness.
2. **Manifest v1.2** — [`09_SOP/bootstrap-manifest.json`](../../09_SOP/bootstrap-manifest.json) adds `readiness` + `enforcement` fields pointing at the checker.
3. **ADR-0012** — [Automated Bootstrap Gate](../../04_ADR/ADR-0012-automated-bootstrap-gate.md) extends ADR-0009 (mandatory bootstrap).
4. **Readiness standard** — [`09_SOP/SESSION_READINESS.md`](../../09_SOP/SESSION_READINESS.md).
5. **Tests** — [`scripts/tests/test-check-bootstrap.ps1`](../../scripts/tests/test-check-bootstrap.ps1) (33 assertions: PASS / FAIL / WARN / `-Strict`).
6. **CI hook** — [`.github/workflows/bootstrap-gate.yml`](../../.github/workflows/bootstrap-gate.yml) on push/PR to `main`.

## Upgrade notes

- Run the gate at session start ([AGENT_BOOTSTRAP](../../09_SOP/AGENT_BOOTSTRAP.md) Step 0) before assigned work.
- WARN does not fail the process unless `-Strict` is set.
- Existing v1.4 compiler / optimizer tooling is unchanged.
- After push, confirm the **Bootstrap Gate** workflow is green on GitHub Actions.

## Related

- Pack index: [README.md](README.md) · readiness: [RELEASE_READINESS.md](RELEASE_READINESS.md)
- Changelog: [CHANGELOG.md](../../CHANGELOG.md) (`[v1.5.0-alpha.1]`)
