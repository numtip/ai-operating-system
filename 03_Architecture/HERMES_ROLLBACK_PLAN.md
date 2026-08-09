# Hermes Local-First Rollback / Fallback Plan

**Date:** 2026-08-09
**Branch:** `integration/v1.6-hermes-first`
**Status:** Design v0.1 — no Hermes installed; this plan is a v1.6 exit criterion (ROADMAP) to be executed only with human approval (ADR-0013).
**Scope:** Local-first, reversible. Covers the compatibility spike and pilot on a workstation only. No VPS/production surface.

## 1. Pre-install snapshot

Before any Hermes installation (approval-gated):

- [ ] Record baseline: current git SHA (`git rev-parse HEAD`) of `ai-operating-system` and all governed pilot repos.
- [ ] Snapshot environment: list of installed runtimes/CLIs that Hermes would touch (e.g. docker, node, python) — versions only, no secrets.
- [ ] Snapshot AI-OS config: bootstrap manifest, prompt-compiler profiles, context indexes — confirm all are Git-tracked and clean (`git status`).
- [ ] Record pre-install behavioral baseline: run existing gates (`scripts/check-bootstrap.ps1`, prompt-compiler tests) and save results.
- [ ] Confirm no secrets, tokens, or credentials will be touched by install (STOP rule).
- [ ] Verify disk/log paths Hermes would use are outside canonical knowledge stores (no writes to Obsidian/Git knowledge without governance flow).

## 2. Configuration isolation

- Hermes config lives in its own directory, never merged into AI-OS canonical config.
- AI-OS runtime/config files remain read-only from Hermes except through the adapter contract (`HERMES_ADAPTER_CONTRACT.md`).
- Runtime state is ephemeral and disposable by design; nothing durable is written inside Hermes state.
- Environment variables for the spike are scoped to the spike process only; no persistent profile edits.
- Adapter contract fields (`credential_ref`, task grants) must not introduce new global credentials.

## 3. Uninstall / disable procedure

Local-first rollback = revert to pre-install state:

1. Stop Hermes runtime and any scheduled jobs (kill processes, disable auto-start).
2. Remove or rename Hermes config directory; do not delete blindly — move to `backup/<timestamp>/` first.
3. Restore environment from pre-install snapshot (undo PATH/profile/registry changes).
4. Remove Hermes-specific data/logs outside canonical knowledge stores.
5. Verify: `git status` clean for governed repos; baseline gates pass again.
6. No production/DNS/VPS surface is touched at any point (design-only).

## 4. Manual / alternative-runtime continuation

If Hermes is unavailable or fails:

- AI-OS Control Plane continues to operate: context engine, bootstrap gate, prompt quality gate, knowledge — none depend on Hermes (Blueprint V4 §6: replaceable runtime).
- Task execution falls back to the existing v1.0-v1.5 manual/semi-automated path (PowerShell scripts, direct agent execution) — the pre-pilot operating mode remains valid.
- n8n continues to own deterministic integration workflows; no dependency created.
- A pending `task_id` is either completed manually or returned to human review; never silently dropped.

## 5. Knowledge and audit preservation

- Canonical knowledge, project memory, ADRs, and governance artifacts remain in Git (source of truth) — never written by Hermes runtime memory (adapter contract §9).
- All spike/pilot audit records (task_id, actor, context version, model, tools, approval, result) are exported to the repo audit location before any rollback begins.
- Session records follow the existing `07_Memory/sessions/` convention.
- Hermes runtime state, if any, is snapshotted (not deleted) before removal for evidence.

## 6. Failure triggers

Rollback is triggered when any of these occur:

- Unauthorized mutation detected (any write outside approved task scope).
- Secret exposure or credential-scope violation.
- Quality/validation gate fails repeatedly and cannot be escalated.
- Canonical knowledge or Git state is modified outside the governance flow.
- Approval boundary bypass attempted.
- Spike cannot be completed reversibly (e.g. install altered system state).

## 7. Recovery verification

Post-rollback, verify:

- [ ] `git diff` clean against pre-install SHA for governed repos.
- [ ] Baseline gates pass (bootstrap + prompt compiler tests) with same results as pre-install snapshot.
- [ ] Canonical knowledge files unchanged (hash compare where practical).
- [ ] No Hermes processes/configs remain active.
- [ ] Audit records from the spike are preserved in repo.
- [ ] Manual execution path works (a known small task completes without Hermes).

## 8. Exit criteria linkage

This plan satisfies ROADMAP v1.6 exit criterion: "Local-first rollback plan documented." Full execution remains gated on human approval before install (ADR-0013, Blueprint V4 §21.4).
