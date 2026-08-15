# Profile: Hermes

**profile_id:** `hermes`
**Status:** Active locally — v1.6 alpha (ADR-0013/ADR-0014)
**Phase:** v1.6 shared memory and bounded runtime integration

## Fit

- Native memory, skills and FTS5 session recall
- Orchestration / bounded runtime execution
- Head-to-runtime task handoff through approved client surfaces

## Prompt biases

- Prefer native Hermes retrieval before adding prompt context
- Keep task boundaries, approvals and canonical-source pointers explicit

## Capability affinity

`memory`, `session_search`, `tool_use`, `planning`

## Compiler notes

- Local memory/session integration is live and version-pinned
- Model-provider use still requires separately configured credentials
- No Telegram, VPS, deployment or production binding is implied
