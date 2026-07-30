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

## generate-indexes

Regenerates `12_Indexes/*.json` from repo metadata (path/title/tags only; no document bodies).

```powershell
pwsh -File scripts/generate-indexes.ps1
# or Windows PowerShell 5.x:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/generate-indexes.ps1
```

Exit `0` on success, `1` on failure.

## validate-indexes

Parses index JSON and checks that every `path` exists on disk.

```powershell
pwsh -File scripts/validate-indexes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-indexes.ps1
```

Exit `0` on pass, `1` on fail.

## validate-v1.1

Runs structure + indexes validation, then reports session count vs `07_Memory/compression/THRESHOLD.json` (default 25). Missing threshold file → WARN skip.

```powershell
pwsh -File scripts/validate-v1.1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-v1.1.ps1
```

## check-session-threshold

Counts `*.md` session files under `07_Memory/sessions` (excludes `archive/`) and compares to `07_Memory/compression/THRESHOLD.json`.

```powershell
pwsh -File scripts/check-session-threshold.ps1
pwsh -File scripts/check-session-threshold.ps1 -FailOnThreshold
```

| Result | Meaning | Exit |
|--------|---------|------|
| PASS | count &lt; threshold | 0 |
| WARN | count ≥ threshold (default) | 0 |
| FAIL | count ≥ threshold with `-FailOnThreshold` | 1 |
