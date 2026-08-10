# Obsidian Local Install — Evidence Record

- **Date**: 2026-08-09
- **OS**: Windows 10.0.26200 (PowerShell)
- **Authorized task**: Real local Obsidian installation + AI-OS vault setup

## 1. Install

| Field | Value |
|---|---|
| Command | `winget install --id Obsidian.Obsidian -e --accept-source-agreements --accept-package-agreements --silent` |
| Result | `Successfully installed` (downloaded `Obsidian-1.13.4.exe` from GitHub releases, installer hash verified) |
| Exit code | `0` |
| Installed version | `1.13.4` (winget list: `Obsidian.Obsidian 1.13.4 winget`; exe `FileVersion 1.13.4`) |
| Exe path | `C:\Users\prinya\AppData\Local\Programs\Obsidian\Obsidian.exe` |

## 2. Vault

| Field | Value |
|---|---|
| Vault root | `F:\projectAi\ai-operating-system` (repo root; repo Markdown remains source of truth) |
| Config dir | `F:\projectAi\ai-operating-system\.obsidian\` |

`.obsidian` files created (all validated as valid JSON via `ConvertFrom-Json`):

- `app.json` → `{"showUnsupportedFiles": true}`
- `core-plugins.json` → `{"file-explorer": true, "search": true}`
- `appearance.json` → `{}`

## 3. Vault index note

- Path: `F:\projectAi\ai-operating-system\00_Dashboard\VAULT_INDEX.md`
- Links (relative paths, no content duplication) to:
  - `03_Architecture/AI_OPERATING_SYSTEM_BLUEPRINT_V4.md`
  - `03_Architecture/ARCHITECTURE_OVERVIEW.md`
  - `03_Architecture/ROADMAP.md`
  - `07_Memory/CURRENT_STATE.md`
  - `07_Memory/SYSTEM_MEMORY.md`
  - `06_Research/pilots/v1.6-hermes/LOCAL_INTEGRATION_VALIDATION_REPORT.md`
  - `06_Research/pilots/v1.6-hermes/HERMES_PREFLIGHT_REPORT.md`
  - `06_Research/pilots/v1.6-hermes/goffice2026/STAGE-1-RESULTS.md`

## 4. Launch verification

| Attempt | Method | Result |
|---|---|---|
| 1 | `Start-Process "obsidian://open?path=F:\projectAi\ai-operating-system"` | No Obsidian process detected after 6 s (protocol handler not registered on first run) |
| 2 | `Start-Process Obsidian.exe '"F:\projectAi\ai-operating-system"'` | **Success** — Obsidian processes running (PID 9144 + 3 Electron children, all started 2:47:58 PM) |
| Vault recognition | After launch, `.obsidian` contained exactly the 3 created config files (no errors, no overwrites) | Config loaded intact |

- App present: yes (version 1.13.4)
- `.obsidian` config valid JSON: yes (all 3 files)
- Index note exists: yes
- GUI open verification: process-level only — Obsidian launched and ran with the vault path argument; visual confirmation of the vault window is limited in this headless shell context.

Obsidian was closed cleanly after verification (`Stop-Process`, no remaining processes).

## 5. Gitignore recommendation

- `.obsidian\` and `.runtime\` must be gitignored (workspace/cache, not source of truth).
- Current `.gitignore` already covers Obsidian volatile files (`.obsidian/workspace*`, `.obsidian/cache`, `.trash/`) while keeping core config tracked.
- Added `.runtime/` to `.gitignore` (was untracked, not ignored).
- Nothing was committed (head agent handles commits).

## 6. Blockers

- None. `obsidian://` URI launch did not work on first attempt (protocol handler not yet registered); direct exe launch with vault path succeeded instead.
