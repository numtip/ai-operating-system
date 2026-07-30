# Scripts

## validate-structure

Verifies required top-level folders and required memory/governance/template files.

### PowerShell (Windows / cross-platform)

From repo root:

```powershell
# PowerShell 7+
pwsh -File scripts/validate-structure.ps1

# Windows PowerShell 5.x
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-structure.ps1
```

### Bash

From repo root:

```bash
bash scripts/validate-structure.sh
```

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | All checks PASS |
| non-zero | One or more checks FAIL |

Each check prints `PASS` or `FAIL`. Summary line: `RESULT: PASS` or `RESULT: FAIL (N check(s) failed)`.
