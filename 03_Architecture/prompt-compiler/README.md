# Prompt Compiler

**Status:** Spec + runtime (v1.3)  
**Scope:** Compile structured task inputs into short, routable prompts.  
**Runtime:** [`prompt-compiler/`](../../prompt-compiler/) + [`scripts/compile-prompt.ps1`](../../scripts/compile-prompt.ps1) (no API).  
**Out of scope:** API calls, SDK clients, live model invocations, credential handling.

## Purpose

Define the canonical contract for turning Head→subagent (or Head→model) task briefs into:

1. A **compiled prompt** that meets `SHORT_PROMPT_STANDARD.md`
2. A **routing decision** (profile + model class fields only)
3. A **validation checklist** against `OUTPUT_CONTRACT.md`

Contract docs live in this package; the executable runtime lives under repo-root `prompt-compiler/` (ADR-0011).

## Spec index

| Spec | Role |
|------|------|
| [INPUT_SCHEMA.md](INPUT_SCHEMA.md) | Canonical input fields for compilation |
| [OUTPUT_CONTRACT.md](OUTPUT_CONTRACT.md) | Required shape of compiled output |
| [ROUTING.md](ROUTING.md) | Model routing fields (declarative) |
| [SHORT_PROMPT_STANDARD.md](SHORT_PROMPT_STANDARD.md) | Length, structure, and style rules |
| [profiles/](profiles/) | Per-provider prompt profile notes |

## Profiles

| Profile | File | Phase |
|---------|------|-------|
| GPT | [profiles/gpt.md](profiles/gpt.md) | Active (spec) |
| DeepSeek | [profiles/deepseek.md](profiles/deepseek.md) | Active (spec) |
| Claude | [profiles/claude.md](profiles/claude.md) | Active (spec) |
| Gemini | [profiles/gemini.md](profiles/gemini.md) | Active (spec) |
| Hermes | [profiles/hermes.md](profiles/hermes.md) | Deferred (Phase 2 placeholder) |

## Related templates

- [../../11_Templates/SUBAGENT_TASK_PROMPT.md](../../11_Templates/SUBAGENT_TASK_PROMPT.md) — Head→subagent task prompt template
- [../../11_Templates/AGENT_TASK_TEMPLATE.md](../../11_Templates/AGENT_TASK_TEMPLATE.md) — existing agent task brief

## Non-goals

- Calling any provider API
- Selecting live endpoints or keys
- Binding to a specific orchestration runtime (Hermes deferred)
