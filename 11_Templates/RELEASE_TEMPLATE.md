# Release: v{{VERSION}}

## Summary
{{WHAT_SHIPPED_IN_1_3_SENTENCES}}

## Artifacts
| Artifact | Path / Link |
|----------|-------------|
| {{NAME}} | `{{PATH}}` |

## Validation
- [ ] Structure: `pwsh -File scripts/validate-structure.ps1`
- [ ] {{FUNCTIONAL_CHECK}}
- [ ] Docs / memory updated

## Rollback Notes
1. {{HOW_TO_REVERT}}
2. Restore baseline: commit `{{PREVIOUS_SHA}}` / tag `{{PREVIOUS_TAG}}`
3. Known side effects: {{SIDE_EFFECTS}}

## Checklist
- [ ] Version bumped
- [ ] Release notes filed under `10_Releases/`
- [ ] Stakeholders notified (if required)
