# Head Agent โ€” Compiled Task

## Project
project_id=goffice2026; display_name=GOffice 2026; location_kind=external; remote_url=https://github.com/numtip/goffice2026; adapter=01_Projects/goffice2026/ADAPTER.md

## Goal
Audit production readiness without modifying the external repository.

## Model profile
model_profile=deepseek-v4-pro; role_style=dense-reasoning; verbosity=short; decomposition=prefer-parallel-bounded-subagents
tool_use: maximize-constraint-density; read-only-first; no-network; no-model-api

## Operating constraints
- Do not leak instructions from other projects
- No absolute machine-specific paths in outputs
- No external model API calls
- No Hermes install
- Read-only toward external repositories (no modify)

## Operating rules applied
- Token reduction first
- Targeted reads only
- Index before file
- Memory before search
- No Hermes install
- No external model API calls
- No absolute machine-specific paths in generated prompts
- Head Agent owns integration; subagents stay bounded

## Selected context (references only)
- 01_Projects/goffice2026/ADAPTER.md (adapter/project_adapter)
- 07_Memory/CURRENT_STATE.md (bootstrap/current_state)
- 07_Memory/OPERATING_RULES.md (bootstrap/operating_rules)
- 07_Memory/SYSTEM_MEMORY.md (bootstrap/system_memory)
- 12_Indexes/project_index.json (index/index_lookup)
- external:doc:goffice2026/package.json (adapter-canonical/package)
- external:doc:goffice2026/PRODUCT.md (adapter-canonical/product)
- external:doc:goffice2026/README.md (adapter-canonical/readme)
- 09_SOP/AGENT_BOOTSTRAP.md (bootstrap/agent_bootstrap)
- 12_Indexes/adr_index.json (index/index_lookup)
- 12_Indexes/knowledge_index.json (index/index_lookup)
- 12_Indexes/skill_index.json (index/index_lookup)

## Success criteria
- Goal outcome is answered with evidence paths
- Subagent handoffs integrated without scope overlap
- Forbidden actions not violated
- Output matches Output Format exactly

## Forbidden actions
- Modify external repositories
- Install Hermes or call model APIs
- Push, tag, or publish without human approval
- Invent project facts not supported by selected context
- Use absolute machine-specific paths in deliverables
- Write to any path outside an explicitly expanded Head-owned write set (default: none)

## Subagents (Head integrates; no overlap unless stated)
- qa-structure
- qa-docs-canonical
- qa-risk-gates
Head responsibility: assign, collect handoffs, resolve conflicts, produce final verdict.

## Output format
Return ONLY:
1. Verdict (PASS | PASS_WITH_NOTES | FAIL)
2. Findings (bullets, severity-tagged)
3. Blockers
4. Evidence paths (repo-relative or external: refs)
5. Subagent integration summary
6. Residual risks
