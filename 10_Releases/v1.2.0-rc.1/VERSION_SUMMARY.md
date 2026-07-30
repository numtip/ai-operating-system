# Version Summary — v1.2.0-rc.1

| Field | Value |
|-------|--------|
| Version | v1.2.0-rc.1 |
| Codename | Knowledge Index Maturity (pilot RC) |
| Prior tag | v1.1.0-alpha.1 |
| Repo | https://github.com/numtip/ai-operating-system |
| Pilot | goffice2026 (external; adapter in-vault) |

## Capability delta vs v1.1

| Area | v1.1 | v1.2 RC |
|------|------|---------|
| Project registration | empty `project_index` | Adapter + indexed goffice2026 |
| Bootstrap | SOP/manifest only | + runtime spec + simulator |
| Metrics | compression threshold | + context efficiency benchmarks |
| Validation | structure/indexes | + real-project pilot (~98.9% reduction) |

## Commit series (unpublished until push)

1. `feat(adapter): add project adapter specification`
2. `feat(bootstrap): add bootstrap runtime specification`
3. `feat(metrics): add context efficiency benchmark`
4. `docs(validation): add goffice2026 pilot validation`
5. `docs(memory): update operational memory`

(+ RC readiness docs commit recommended before tag)

## Next

v1.3 Prompt Compiler Runtime
