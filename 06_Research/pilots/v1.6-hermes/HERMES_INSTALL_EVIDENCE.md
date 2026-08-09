# Hermes Agent — Real Local Install Evidence

**Status:** INSTALL_OK
**Date:** 2026-08-09 (UTC+7)
**Host:** Windows 10.0.26200 (win32), PowerShell
**Performed by:** AI subagent (authorized local install; no API keys, no credentials, no external model API calls)

---

## 1. Install target / isolation

- Sandbox root: `F:\projectAi\ai-operating-system\.runtime\hermes-agent` (created under `.runtime\`, per constraints)
- No global/system install, no Docker, no service, no ports, no PATH/profile edits, no VPS.
- No API keys/tokens/credentials set up or used.
- No tasks executed that call external model APIs.
- External repos untouched (`F:\projectAi\goffice2026` not modified). Nothing committed (head agent handles commits).

## 2. Source / tag verification

| Field | Value |
|---|---|
| Clone URL | `https://github.com/NousResearch/hermes-agent.git` |
| Branch / tag | `v2026.8.3` (annotated tag) |
| Clone command | `git clone --branch v2026.8.3 --depth 1 ...` → succeeded (depth 1) |
| `git rev-parse v2026.8.3` | `7de39e700d2c329e15d32eb0b96e2f7cdd9fbdb2` (tag **object** SHA — annotated tag) |
| `git rev-list -n 1 v2026.8.3` (peeled commit) | `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` ✅ |
| `git rev-parse HEAD` | `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` ✅ |
| **Required SHA** | `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` → **MATCH (verified)** |

Note: because the tag is *annotated*, raw `rev-parse v2026.8.3` returns the tag object; the peeled commit (and the checked-out HEAD) equals the required SHA exactly. Verification **passed**; install proceeded.

### Tag signature status

- Tagger: `Teknium <127238744+teknium1@users.noreply.github.com>` — "Hermes Agent v0.20.0 (2026.8.3) — The Herald Release"
- Signature type: **SSH signature, key type `ssh-ed25519`**, namespace `git`, hash `sha512` (parsed from the tag's `-----BEGIN SSH SIGNATURE-----` blob).
- `git tag -v v2026.8.3` (default): FAILS to verify — `error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification` (exit 1). Expected: no global signers file configured on this machine.
- Verification with local allowed-signers file (public key extracted from the tag signature itself, no network):
  `git -c gpg.ssh.allowedSignersFile=F:\projectAi\ai-operating-system\.runtime\allowed_signers tag -v v2026.8.3`
  → `Good "git" signature for * with ED25519 key SHA256:x9xNOpeJhoEAY2gWhmWHZROC3QF3VjOEbmNo9vQ8y2A` (exit 0).
- Caveat: key is the one embedded in the signature (self-consistent cryptographic validation). Cross-checking the key against Teknium's GitHub identity was **not** performed — that would require a GitHub API fetch beyond the allowed network scope (git clone + pip only).

## 3. License

- **MIT** — `LICENSE`: "MIT License / Copyright (c) 2025 Nous Research". Declared in `pyproject.toml`: `license = "MIT"`.

## 4. Environment

- Base Python: `Python 3.12.10` (`C:\Users\prinya\AppData\Local\Programs\Python\Python312\python.exe`) — satisfies `requires-python = ">=3.11,<3.14"`.
- Venv: `F:\projectAi\ai-operating-system\.runtime\hermes-agent\.venv`
- pip upgraded in-venv to `26.2.1`.

## 5. Install command + result

```
cd F:\projectAi\ai-operating-system\.runtime\hermes-agent
.\.venv\Scripts\python.exe -m pip install -e .
```

Result: **SUCCESS (exit 0)** — `Successfully built hermes-agent`, editable wheel `hermes_agent-0.20.0-0.editable-py3-none-any.whl`, `Successfully installed hermes-agent-0.20.0` + all exact-pinned core deps (download from PyPI, allowed). Full log: `.runtime\pip_install_log.txt`.

### Installed package versions (hermes-relevant, `pip freeze`)

```
-e git+https://github.com/NousResearch/hermes-agent.git@3c27eb6234bf91b8ceee9e9071591b31e9b148cb#egg=hermes_agent
cryptography==48.0.1      fastapi==0.141.1        fire==0.7.1
httpx==0.28.1             nemo-relay==0.6.0       openai==2.24.0
pydantic==2.13.4          pydantic_core==2.46.4   pywin32==311
pywinpty==2.0.15          rich==14.3.3            starlette==1.6.0
uvicorn==0.52.1
```

(Plus exact-pinned core: certifi, concurrent-log-handler, croniter, jinja2, Markdown, packaging, pathspec, Pillow, prompt_toolkit, psutil, PyJWT, python-dotenv, python-multipart, pyyaml, requests, ruamel.yaml, tenacity, tzdata, urllib3, websockets. CLI entry points: `hermes`, `hermes-agent`, `hermes-acp`.)

## 6. Smoke tests (exact commands, output summary, exit codes)

### `hermes --version` → exit 0
```
Hermes Agent v0.20.0 (2026.8.3)
Install directory: F:\projectAi\ai-operating-system\.runtime\hermes-agent
Python: 3.12.10
OpenAI SDK: 2.24.0
```

### `hermes --help` → exit 0
Full usage printed (59 subcommands: chat, doctor, model, status, sessions, skills, config, tools, mcp, gateway, dashboard, etc.; options: `-z/--oneshot`, `--provider`, `--safe-mode`, `--ignore-user-config`, `--resume`, etc.). Output saved: `.runtime\hermes_help.txt`.

### `hermes doctor` (self-test/doctor present) → exit 0
- Python 3.12.10 ✓, venv active ✓, version files consistent (0.20.0) ✓
- SSL CA bundle ✓, required packages ✓, SQLite 3.49.1 ⚠ (WAL-reset bug warning, upstream fix)
- `.env` missing ⚠ (expected — fresh install; `hermes setup` would create), `config.yaml` not found (defaults) ⚠
- Auth providers: all not logged in (Nous Portal / Codex / MiniMax / xAI) — expected
- API connectivity: OpenRouter not configured ⚠; DeepSeek endpoint reachable ✓ (connectivity probe only, no keys used)
- Tools: core tools available; web/x_search/discord etc. disabled (missing keys) — expected
- Found 2 issues: run `hermes setup` to create `.env` / configure API keys. Output saved: `.runtime\hermes_doctor.txt`.

## 7. Offline-capability finding

**Running an actual agent task REQUIRES a model provider API key: YES.**

- All 33 bundled provider plugins (`plugins/model-providers/`) are cloud inference APIs (anthropic, openai, openrouter, gemini, deepseek, xai, ...) using `api_key` or OAuth — none is offline.
- `custom` provider can point at a local OpenAI-compatible endpoint (Ollama/LM Studio, `base_url` override), but that requires **running a local server on a port** — forbidden by constraints (no service / no ports). No `mock`/`echo`/`demo`/`template` provider exists.
- No `hermes run --dry-run` task mode. `--dry-run` exists only on management subcommands (`curator run --dry-run`, `claw migrate --dry-run`, `gateway --dry-run`, `uninstall --dry-run`, `import-agent --dry-run`) — previews of maintenance ops, not task execution.
- Offline-capable commands (no keys, no external API): `hermes doctor` (verified working), `hermes status`, `hermes dump`, `hermes logs`, `hermes sessions list`, `hermes prompt-size`. These are diagnostics — not agent task runs.
- **Verdict: tasks cannot run without API keys (N) under the sandbox constraints; offline diagnostics run fine.**

## 8. Blockers

- **None blocking.** Install, SHA, signature, venv, pip install, and all smoke tests completed.
- Non-blocking notes: (a) SQLite 3.49.1 WAL-reset warning from `doctor` (upstream advisory, not install-relevant); (b) default `git tag -v` needs a global `gpg.ssh.allowedSignersFile` — provided locally for this evidence run; (c) task execution deferred (requires API key, out of scope).

## 9. Gitignore

- `F:\projectAi\ai-operating-system\.gitignore` already contains `.runtime/` (line 39, comment "AI-OS local runtime cache (Obsidian vault side-effects)"). Verified with `git check-ignore -v .runtime\hermes-agent\.venv\Scripts\hermes.exe` → matches rule. **No .gitignore change needed**; the whole sandbox stays out of git.
