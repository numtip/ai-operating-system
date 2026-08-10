# Hermes Install — Preflight & Gate-B STOP Record

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Status:** **STOPPED** — no installation performed.
**Authorization context:** Gate B approval granted for a pinned, reversible, repo-local Hermes sandbox install. Per execution rules: *"If official Hermes source or exact install method is ambiguous, STOP and report; do not guess or substitute a package."*

## 1. Pre-install snapshot (required evidence)

| Item | Value |
|---|---|
| Git HEAD | `697d118df7c0063006ccaaaf217bb7711438f90f` |
| Branch | `integration/v1.6-hermes-first` |
| Working tree | clean (nothing to commit) |
| Remote | `origin` in sync at `697d118` |
| Hermes installed | **NO** (never was) |
| Dependencies downloaded | **NONE** |

## 2. Why installation was stopped (ambiguity evidence)

Repository defines "Hermes" only as an **architectural role**, never as a product:

- `ADR-0013`: "Hermes is the preferred orchestration/runtime layer" — role, no product identity.
- `Blueprint V4 §6`: "preferred orchestration **candidate**"; §21.4: "installation is not implied by this document".
- `HERMES_ADAPTER_CONTRACT.md`: explicitly "implementation-neutral… free of implementation details (language, SDK, transport) until the compatibility spike selects them".
- `prompt-compiler/profiles/hermes.md`: "Status: Deferred placeholder… Replace this file when Phase 2 routing is specified".
- Bootstrap manifest `09_SOP/bootstrap-manifest.json` lists `no_hermes` as a constraint (prohibition, not specification).

**No official source URL, package manager, version, or checksum is pinned anywhere in the repo.**

## 3. Preflight finding (subagent, 2026-08-09)

Verdict: **AMBIGUOUS**. Real-world "Hermes" candidates exist but none is identified as the intended runtime:

| Candidate | Official source | Install | Fit to Blueprint §6 |
|---|---|---|---|
| Hermes Agent (Nous Research) | github.com/NousResearch/hermes-agent · PyPI `hermes-agent` | pip / curl / Docker | Closest functional fit (agent orchestration) — observation only |
| Meta Hermes JS engine | github.com/facebook/hermes | bundled via React Native | Not an orchestration runtime |
| Hermes LLM models | huggingface.co/NousResearch/Hermes-4 | model weights | Models, not runtime |
| hermes-workflow (PyPI) | pypi.org/project/hermes-workflow | pip | Plugin on Hermes Agent |
| hermes-dynamic-workflows | github.com/lingjiuu/hermes-dynamic-workflows | hermes plugin | Plugin on Hermes Agent |

Choosing any of these without owner direction = **guessing/substituting**, which the rules prohibit.

## 4. Action taken

- **STOPPED install.** No Hermes, no package, no Docker, no service, no PATH/profile edit, no network targets, no credentials touched.
- `F:\projectAi\goffice2026` untouched. No production/external system touched.
- No vendored binaries/node_modules created. Nothing to roll back (nothing installed).
- This record is the install audit evidence: install did not proceed; blocker documented.

## 5. Owner decision required (before any Gate B install can proceed)

1. **Pin the product:** which "Hermes" is intended (e.g. Hermes Agent @ Nous Research, or another).
2. **Pin exact version:** version tag + commit SHA.
3. **Pin source + install method:** official URL and exact install command.
4. **Record the pin** in an ADR/appendix so the sandbox is genuinely pinned and reversible (per `HERMES_ROLLBACK_PLAN.md` §1).

Once pinned, re-authorize; then install may proceed strictly under the sandbox rules (repo-local dir, no global/system/Docker/service/ports/PATH, smoke-only, rollback dry-run, docs+lock+scripts committed only).

## 6. No false claims

No Hermes compatibility, no production safety, no installation performed. This is a STOP/blocker record, not an install record.
