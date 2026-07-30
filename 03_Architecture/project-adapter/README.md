# Project Adapter

A **Project Adapter** is a thin pointer layer inside AI-OS that links an AI-OS project entry to an external or in-vault project. Adapters **point**; they do **not** own or duplicate project documentation.

## Purpose

- Give agents a single, stable entry for “how do I load this project?”
- Separate AI-OS vault concerns from project-owned docs (PRODUCT, DESIGN, constitution, etc.)
- Enforce **link-don’t-copy**: canonical content lives in the project; the adapter only references it

## What an adapter exposes (ONLY)

| Surface | Role |
|---------|------|
| **Metadata** | Identity, status, ownership — short facts only |
| **Repository** | Where the project lives (local path, remote URL, branch, tip) |
| **Current state** | One-line / short status pointer — not a narrative dump |
| **Canonical documents** | Paths to project-owned docs (relative to project root) |
| **Memory entry** | Path to AI-OS project memory (vault-relative) |
| **Bootstrap path** | How to start an agent session for this project |

No other surfaces. Do not embed PRODUCT/DESIGN/CHANGELOG bodies, runbooks, or research dumps inside the adapter.

## Link-don’t-copy rule

1. **Reference by path** (or URL), never paste full document content into the adapter or `01_Projects/<id>/` pointer files.
2. If a doc must change, change it in the **project repository** (or its canonical vault location) — not in the adapter.
3. Summaries in the adapter are limited to short status lines and field values defined in [SPEC.md](SPEC.md).
4. Violations: embedded full docs, mirrored copies of PRODUCT/DESIGN, or re-hosted constitution text under `01_Projects/`.

## Related

- Schema & validation: [SPEC.md](SPEC.md)
- Fill-in template: [../../11_Templates/PROJECT_ADAPTER.md](../../11_Templates/PROJECT_ADAPTER.md)
- Agent bootstrap: [../../09_SOP/AGENT_BOOTSTRAP.md](../../09_SOP/AGENT_BOOTSTRAP.md)
- Context loading: [../PROJECT_CONTEXT_LOADING.md](../PROJECT_CONTEXT_LOADING.md)
