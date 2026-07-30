# Prompt Compiler Result

**Status:** ok
**Hash:** 8e10defefc04262594603d8e1debaa7c0e3b784bf9b23b568122fec1df9914b3

## Warnings
- optional_missing_context: 01_Projects/document-center/PRODUCT.md
- optional_missing_context: 01_Projects/document-center/PIPELINE.md

## Head Agent Prompt

```text
# Head Agent โ€” Compiled Task

## Project
project_id=document-center; display_name=Document Center; location_kind=in_vault; adapter=01_Projects/document-center/ADAPTER.md

## Goal
Inspect publication pipeline readiness and identify blocking issues.

## Model profile
model_profile=claude-coding; role_style=careful-coding; verbosity=short; decomposition=explicit-file-owned-subagents; no-overlap
tool_use: plan-then-edit; explicit-write-scope; no-network; no-model-api; no-commit-unless-asked

## Operating constraints
- Do not leak instructions from other projects
- do not load goffice2026 instructions
- No absolute machine-specific paths in outputs
- No external model API calls
- No Hermes install
- read-only
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
- 01_Projects/document-center/ADAPTER.md (adapter/project_adapter)
- 07_Memory/CURRENT_STATE.md (bootstrap/current_state)
- 07_Memory/OPERATING_RULES.md (bootstrap/operating_rules)
- 07_Memory/SYSTEM_MEMORY.md (bootstrap/system_memory)
- 12_Indexes/project_index.json (index/index_lookup)
- 01_Projects/document-center/README.md (project/project_entry)
- 03_Architecture/CONTEXT_ENGINE.md (knowledge_index/goal_match)
- 04_ADR/ADR-0001-local-first-development.md (adr_index/goal_match)
- 04_ADR/ADR-0007-prompt-compiler-specification-first.md (adr_index/goal_match)
- 07_Memory/projects/document-center.md (memory/project_memory)
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
- inspect-pipeline
- inspect-blockers
Head responsibility: assign, collect handoffs, resolve conflicts, produce final verdict.

## Output format
Return ONLY:
1. Verdict (PASS | PASS_WITH_NOTES | FAIL)
2. Findings (bullets, severity-tagged)
3. Blockers
4. Evidence paths (repo-relative or external: refs)
5. Subagent integration summary
6. Residual risks
```

## Subagent Prompts

### inspect-pipeline

```text
## Subagent: inspect-pipeline
## Assigned objective
Inspect publication/pipeline readiness signals for document-center.

## Scope mode
read-only

## Allowed files or indexes
- 01_Projects/document-center
- 12_Indexes/
- 07_Memory/OPERATING_RULES.md
- 07_Memory/SYSTEM_MEMORY.md
- 07_Memory/CURRENT_STATE.md
- 01_Projects/document-center/ADAPTER.md
- 07_Memory/projects/document-center.md
- 03_Architecture/
- 09_SOP/
- 11_Templates/

## Forbidden scope
- Do not call external model APIs
- Do not copy foreign project instructions into this project context
- Do not copy instructions from other projects
- Do not install Hermes
- Do not load goffice2026 adapter or memory
- Do not modify external repositories
- Do not push or tag
- Write scope: none (read-only audit)

## Expected deliverable
Pipeline readiness notes + missing pieces

## Validation requirements
- [ ] Only this project context
- [ ] Blocking issues labeled
- [ ] No cross-project instruction leak

## Output limit
- Verbosity: short
- Max words: 250
- No nested lists

## Handoff format
Return ONLY:
- findings (bullets)
- blockers
- evidence paths (repo-relative or external: refs)
- residual risks
```

### inspect-blockers

```text
## Subagent: inspect-blockers
## Assigned objective
List blocking issues preventing publication readiness for document-center.

## Scope mode
read-only

## Allowed files or indexes
- 01_Projects/document-center
- 12_Indexes/
- 07_Memory/OPERATING_RULES.md
- 07_Memory/SYSTEM_MEMORY.md
- 07_Memory/CURRENT_STATE.md
- 01_Projects/document-center/ADAPTER.md
- 07_Memory/projects/document-center.md
- 12_Indexes/
- 07_Memory/CURRENT_STATE.md

## Forbidden scope
- Do not call external model APIs
- Do not copy foreign project instructions into this project context
- Do not install Hermes
- Do not modify external repositories
- Do not overlap inspect-pipeline deep architecture scan
- Do not push or tag
- Do not redesign architecture
- Write scope: none (read-only audit)

## Expected deliverable
Ordered blocker list (P0/P1/P2)

## Validation requirements
- [ ] Each blocker has evidence path
- [ ] No write actions proposed as completed
- [ ] Handoff bounded

## Output limit
- Verbosity: short
- Max words: 250
- No nested lists

## Handoff format
Return ONLY:
- findings (bullets)
- blockers
- evidence paths (repo-relative or external: refs)
- residual risks
```

## Context Manifest
- `01_Projects/document-center/ADAPTER.md` โ€” adapter/project_adapter
- `07_Memory/CURRENT_STATE.md` โ€” bootstrap/current_state
- `07_Memory/OPERATING_RULES.md` โ€” bootstrap/operating_rules
- `07_Memory/SYSTEM_MEMORY.md` โ€” bootstrap/system_memory
- `12_Indexes/project_index.json` โ€” index/index_lookup
- `01_Projects/document-center/README.md` โ€” project/project_entry
- `03_Architecture/CONTEXT_ENGINE.md` โ€” knowledge_index/goal_match
- `04_ADR/ADR-0001-local-first-development.md` โ€” adr_index/goal_match
- `04_ADR/ADR-0007-prompt-compiler-specification-first.md` โ€” adr_index/goal_match
- `07_Memory/projects/document-center.md` โ€” memory/project_memory
- `09_SOP/AGENT_BOOTSTRAP.md` โ€” bootstrap/agent_bootstrap
- `12_Indexes/adr_index.json` โ€” index/index_lookup
- `12_Indexes/knowledge_index.json` โ€” index/index_lookup
- `12_Indexes/skill_index.json` โ€” index/index_lookup

## Metrics

| Metric | Value |
|--------|-------|
| input_size_chars | 227 |
| compiled_prompt_size_chars | 5198 |
| estimated_tokens | 1300 |
| context_files_selected | 14 |
| index_hits | 10 |
| warnings | 2 |
| subagent_count | 2 |
| compilation_duration_ms | 333 |
| deterministic_hash | 8e10defefc04262594603d8e1debaa7c0e3b784bf9b23b568122fec1df9914b3 |
