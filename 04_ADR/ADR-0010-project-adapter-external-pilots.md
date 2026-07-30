# ADR-0010: Project Adapter for External Pilots

- **Status:** Accepted
- **Date:** 2026-07-30

## Context

AI-OS must bootstrap agents for real projects (e.g. goffice2026) without copying project docs into the vault or scanning entire trees.

## Decision

Introduce a **Project Adapter** surface under `01_Projects/<id>/` that exposes only:

1. Metadata  
2. Repository  
3. Current state  
4. Canonical documents (paths only)  
5. Memory entry  
6. Bootstrap path  

Adapters **link**; they do not duplicate. External repos remain outside the vault. Bootstrap runtime reads indexes → adapter → minimum canonical set.

## Consequences

- `project_index.json` registers adapters, not full trees.
- Pilot validation writes findings under `06_Research/pilots/`, not into the external project.
- goffice2026 is the first production pilot; AI-OS must not modify it.

## Alternatives

- Copy project docs into the vault — rejected (duplication).
- Always full-repo scan — rejected (token waste).

## Links

- [project-adapter/SPEC.md](../03_Architecture/project-adapter/SPEC.md)
- [bootstrap-runtime/SPEC.md](../03_Architecture/bootstrap-runtime/SPEC.md)
- [ADR-0005](ADR-0005-context-engine-core-layer.md)
- [ADR-0006](ADR-0006-file-based-indexes-before-vector.md)
