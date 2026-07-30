# Bootstrap Runtime

**Status:** Spec-only (AI-OS v1.2)  
**Scope:** Deterministic project bootstrap — turn a project name into an ordered context package.  
**Out of scope:** LLM calls, Hermes, databases, vector search, external project tree mutation.

## Purpose

Define a lightweight runtime contract that:

1. Reads indexes first
2. Locates canonical project files
3. Loads the minimum context set
4. Emits a bootstrap summary + ordered context package

Agents and humans follow the same steps. No model invocation is required to produce the package skeleton.

## Spec index

| Spec | Role |
|------|------|
| [SPEC.md](SPEC.md) | Algorithm, I/O, stop conditions, token-reduction rules |
| [OUTPUT_SCHEMA.md](OUTPUT_SCHEMA.md) | Bootstrap summary + ordered context package fields |

## Related

- Human/agent SOP: [../../09_SOP/PROJECT_BOOTSTRAP.md](../../09_SOP/PROJECT_BOOTSTRAP.md)
- Session bootstrap (memory-first): [../../09_SOP/AGENT_BOOTSTRAP.md](../../09_SOP/AGENT_BOOTSTRAP.md)
- Ordered-read template: [../../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md](../../11_Templates/context/BOOTSTRAP_CONTEXT_PACKAGE.md)
- Context loading order: [../PROJECT_CONTEXT_LOADING.md](../PROJECT_CONTEXT_LOADING.md)
- Simulation (stdlib PowerShell): [../../scripts/simulate-bootstrap.ps1](../../scripts/simulate-bootstrap.ps1)

## Non-goals

- Calling any LLM or provider API
- Writing under `06_Research/pilots/`
- Modifying external repo trees referenced by adapters
- Owning project-adapter implementation (separate package)
