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

## compile-prompt

Prompt Compiler Runtime (v1.3). Compiles Project + Goal + Model Profile + Constraints into Head/Subagent prompts, context manifest, and metrics. **No LLM / no network.**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compile-prompt.ps1 `
  -Project goffice2026 `
  -Goal "Audit production readiness without modifying the external repository." `
  -ModelProfile deepseek-v4-pro `
  -OutputMode both `
  -OutDir out/compile
```

| Param | Required | Notes |
|-------|----------|-------|
| `-Project` | yes | Project id / `01_Projects/` folder |
| `-Goal` | yes | Non-empty outcome |
| `-ModelProfile` / `-Model` | yes | Profile id under `prompt-compiler/profiles/` |
| `-Constraints` | no | String array; conflicting read-only/write fails |
| `-OutputMode` | no | `json` \| `markdown` \| `both` |
| `-OutDir` | no | Write `compile-result.json` / `.md` |
| `-RepoRoot` | no | Defaults to AI-OS root |

Exit `0` on compile ok, `1` on validation/compile error, `2` if runtime missing.

Tests: `prompt-compiler/tests/run-tests.ps1`  
Docs: `prompt-compiler/README.md`

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

## simulate-bootstrap

Dry-run of the project bootstrap runtime (indexes → locate → minimum context plan → summary). No LLM. Does not modify external trees.

```powershell
pwsh -File scripts/simulate-bootstrap.ps1 -ProjectName <name>
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/simulate-bootstrap.ps1 -ProjectName <name>
```

- Always prints a bootstrap summary to stdout.
- If `01_Projects/<name>/ADAPTER.md` exists, also writes `01_Projects/<name>/last-bootstrap-simulation.md`.
- Exit `0` for completed simulation (`ready` / `not_found` / `degraded`); `1` if `project_index.json` is missing or invalid.

Spec: [../03_Architecture/bootstrap-runtime/SPEC.md](../03_Architecture/bootstrap-runtime/SPEC.md).

## estimate-tokens

Estimate tokens for listed files using Method A (`ceil(chars/4)`). See `03_Architecture/metrics/METRICS_SPEC.md`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/estimate-tokens.ps1 -Paths README.md,AI_OS_MANIFESTO.md
```
