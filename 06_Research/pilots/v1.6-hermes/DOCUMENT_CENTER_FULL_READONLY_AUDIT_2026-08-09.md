# Document Center — FULL READ-ONLY AUDIT — 2026-08-09

**Branch:** `integration/v1.6-hermes-first` (AI-OS)
**Target:** `F:\projectAi\document-center` (external repo; AI-OS adapter `01_Projects/document-center/ADAPTER.md`)
**Mode:** FULL READ-ONLY — no modification to Document Center, no git mutation, no M365/SharePoint/API action, no authenticated access, no production/VPS/Cloudflare, no secrets exposed.
**Executed via:** governed AI-OS pipeline (bootstrap → context compile → quality gate) → Hermes v0.20.0 (sandbox) → DeepSeek direct (`deepseek-v4-flash`).

## 0. Verdict

**FULL_AUDIT_PASS** (execution) — Hermes/DeepSeek verdict: **FAIL** (findings below, CRITICAL 2 / HIGH 2 / MEDIUM 4 / LOW 2).

## 1. Repository identity / tree state (before == after)

| Field | Value |
|---|---|
| Path | `F:\projectAi\document-center` |
| Branch | `preview/pxp5-remediated` |
| HEAD | `9a8cde84630f2818827271efeb9df48ee8758ae2` ("docs(release): record verified Pages URLs and commit SHA in audit report", 2026-08-02) |
| origin/main | `3880651` (production baseline, untouched since 2026-07-16) |
| Tracked | 294 files; **no staged/modified files** |
| Untracked (pre-existing) | `.cursor/`, `mcp-sharepoint/` — untouched |

**No Document Center changes made** — verified: HEAD unchanged, `git status` identical before/after.

## 2. Adapter identity & cross-project isolation

- **F-01 [MEDIUM]** Adapter stale: `ADAPTER.md` says `draft / in_vault / as_of 2026-07-30` with empty remote_url/default_branch/tip_commit while external repo is fully live (main @ 3880651, Pages deployed). `location_kind=in_vault` no longer matches reality.
- Isolation: **GOOD** — vault memory/README forbid goffice2026 inheritance; repo's cross-project mentions are read-only; zero GreenOffice ID contamination (no `ev-`/`doc-` IDs in any registry); no submodule (`.gitmodules` absent); no private DB tracked.

## 3. Architecture boundary (M365 SoR / Lists metadata / GitHub export / portal)

- **Policy compliance: EXCELLENT** — ADR-002 (websites = presentation layers, never master-file stores), ADR-009 (three tiers; "Export 627 to Pages" explicitly rejected as leak), contract §5.2 (private/restricted never exported), §4.2 (sensitive fields never exported).
- **Artifact compliance: FAILS** — committed `data/document-registry.public.json` publishes 124 authenticated tenant URLs (exactly the leak the boundary exists to prevent). Portal boundary honored in staging/preview but violated in the canonical committed artifact.

## 4. Registry/export contract

| Finding | Severity | Detail |
|---|---|---|
| **F-02 Authenticated URL leak** | **CRITICAL** | 124/124 records carry `StorageURL` = `maejo365.sharepoint.com` tenant-authenticated URLs, `DownloadMode=AUTHENTICATED_SHAREPOINT`, 0 PUBLIC links. Validator flags 124/124 as LEAK (P0). Repo is GitHub-Pages-served → internal tenant paths publicly exposed. Pre-documented in `docs/EXPORT_124_ANALYSIS.md` |
| **F-03 Invalid checksum** | **CRITICAL** | Committed `.sha256` (`3afc8ec7…`) matches NEITHER raw file (`f3416efe…`) NOR canonical serialization (`fceca1df…`). CI `sha256sum -c` would fail. Verified manually: mismatch confirmed |
| F-04 Reconciliation metadata | HIGH | Export lacks `excludedCount`/`recordCount` pair (required: recordCount + excludedCount == 627) |
| F-05 Contract/validator drift | MEDIUM | Contract doc (2026-07-14) still allows "SharePoint view-only link" with no auth-URL prohibition; validator ALLOWED_DOWNLOAD_MODES includes AUTHENTICATED_SHAREPOINT while its P0 check forbids auth URLs — self-contradictory |
| F-06 Date format | LOW | `UpdatedDate` full ISO vs contract YYYY-MM-DD |

## 5. Baseline counts (627 / 124 / 503)

**FULLY EVIDENCED** — verified manually: staging `document-registry.remediated.json` → `recordCount=627, publicCount=124, nonPublicCount=503`. Also `reports/pxp5-remediation-matrix-627.csv` (628 lines), `pxp2-export-audit.json` (eligible 124, excluded 503). Note: 503 "internal" = 64 internal + 439 restricted (finer-grained, consistent).

## 6. Schema/manifest/index integrity

- schemaVersion 1.0.0 consistent across public/staging/validator; **duplicate IDs: 0**; deterministic ordering; taxonomy membership valid.
- **F-07 [MEDIUM]** Category naming drift: taxonomy.json uses snake-case slugs (admin, finance-procurement…) vs registry CamelCase (Administration, FinanceProcurement…) — no explicit mapping doc.
- Provenance: staging carries TitleConfidence/Evidence/VisibilityEvidence but 618/627 title-review-required, 456/627 visibility-review-required, 627/627 UrlStatus=BLOCKED_EXTERNAL_ACTION — **provenance pending human verification**, not real yet.

## 7. Non-mutating checks run

| Check | Result |
|---|---|
| `npm test` | FAIL — "Missing script: test" (no test framework defined) |
| `npm run validate:all` | **PASS** (read-only) |
| `npm run validate:pages` | **PASS** (9 routes, v1.0.4) |
| `python validate-public-export.py --sha256-file --expected-total 627` | **FAIL** — 126 errors: 1 checksum + 1 reconciliation + 124 URL leaks (verified manually: 248 leak flags = 124×2) |
| `python validate-pxp5-staging.py` | PASS (627, canonical, checksum OK, 0 leaks) |
| `python check-preview-safe.py` | PASS (PREVIEW_SAFE) |
| NOT run (mutating/M365) | export-live-registry.py, fetch-live-data.py, publish-*.py, verify-links.py — correctly excluded |

## 8. Green Office interoperability vs adapter contract

- **Structurally COMPLIANT**: versioned public JSON + sha256 manifest only; no submodule, no private DB, no private files; goffice2026 referenced read-only; 0 non-RAE IDs.
- **Caveat**: the artifact consumers would pin (committed public export) is the failing/leaking file; the good 627-record artifact lives only in staging/preview.

## 9. Freshness, queues, drift, leakage, evidence

- **F-08 [MEDIUM]** README stale (mtime 2026-07-12, claims FROZEN v1.0.3, 3 demo records) vs actual VERSION=1.0.4 + active PXP-5 branch. CHANGELOG/VERSION current.
- Unresolved queues (human-blocked, documented in `PXP5_HUMAN_ACTION_PACK.md`): 115 titles REVIEW_REQUIRED, **124 URLs BLOCKED_EXTERNAL_ACTION (0/627 URL READY)**, 456 visibility REVIEW_REQUIRED.
- **F-09 [HIGH]** Public-export drift: remediated artifact exists only in staging/preview; committed public JSON untouched + failing; completion audit waves it off as "FAIL by design" — a canonical artifact failing its own P0 gate is not a completed release state.
- Secrets: **no credentials in tracked files**; no `.env` tracked. **F-10 [LOW]** info disclosure: README + registry-export.yml print tenant URLs; untracked `mcp-sharepoint/` (M365 auth tooling) stays out of repo (good isolation, but unmanaged drift).

## 10. Hermes/DeepSeek measurements (this run)

| Metric | Value |
|---|---|
| Provider / model | deepseek direct / `deepseek-v4-flash` |
| API calls | 14 |
| Input tokens | 61,076 |
| Output tokens | 22,582 |
| Total tokens | 691,658 |
| Estimated cost (USD) | **0.0166** |
| Wall latency | ~197 s |
| Verdict | FAIL (CRITICAL 2 / HIGH 2 / MEDIUM 4 / LOW 2) |

**Comparison vs GOFFICE2026 Hermes audit:**

| Metric | GOFFICE2026 | Document Center |
|---|---|---|
| Context files (AI-OS compile) | 8 (target ≤6, hard ≤8 — at hard cap) | **6 (within preferred ≤6)** |
| API calls | 16 | 14 |
| Input tokens | 41,634 | 61,076 |
| Output tokens | 27,425 | 22,582 |
| Total tokens | 643,907 | 691,658 |
| Est. cost USD | 0.0151 | 0.0166 |
| Latency | ~240 s | ~197 s |
| Verdict | PASS_WITH_NOTES | FAIL |
| Traceability | session_id + usage telemetry | same |
| Operator effort | similar (contract → run → evidence) | similar |

## 11. Governance decision (required, exactly one)

**REUSE_EXISTING_SITE_WITH_CONDITIONS**

Rationale:
- Architecture boundary policy is **excellent and correct** (M365 SoR / Lists metadata / GitHub export / portal = presentation; ADR-002/009). The web portal must NOT become DMS/approval/private storage — policy already enforces this and staging/preview pipelines are sound.
- Baseline counts fully evidenced (627/124/503); staging remediated artifact is valid (checksum OK, 0 leaks, canonical).
- **Conditions (mandatory before production/public use):**
  1. **Regenerate `data/document-registry.public.json`** from the staging artifact with validated/masked public StorageURLs (requires 124 public-link creation — human-blocked queue).
  2. **Add `excludedCount` reconciliation metadata** (recordCount + excludedCount == 627).
  3. **Regenerate `.sha256`** over canonical bytes (current committed checksum invalid).
  4. Re-run `validate-public-export.py --sha256-file --expected-total 627` to green; **update `registry-export.yml`** to pass these flags in CI.
  5. Update `ADAPTER.md` (external fields: remote_url/default_branch/tip_commit), README, contract doc (§F-05), category mapping (§F-07).
- Not DEDICATED_SITE_REQUIRED: the site/architecture is sound; the defect is the committed export artifact + metadata, not the site concept.

## 12. Blockers (owner-side, Document Center repo)

1. 124 public link creation (BLOCKED_EXTERNAL_ACTION) — human/SharePoint action.
2. 115 titles + 456 visibility REVIEW_REQUIRED — human verification.
3. Checksum + reconciliation metadata fix + CI flag update — dev action in Document Center repo (owner-initiated, not performed here).

## 13. Explicit statement

**No Document Center changes made** — verified HEAD unchanged (`9a8cde8…`), `git status` identical, no M365/API/GitHub/deploy action, no secrets or authenticated URLs copied into AI-OS evidence (findings reference files/paths only).

## 14. Evidence location

- This report: `06_Research/pilots/v1.6-hermes/DOCUMENT_CENTER_FULL_READONLY_AUDIT_2026-08-09.md`
- Metrics: `06_Research/pilots/v1.6-hermes/DOCUMENT_CENTER_RUNTIME_METRICS.json`
- Raw Hermes output retained in sandbox `.runtime/` (gitignored, not committed)
- **Production recommendation: NO_GO** (unchanged)
