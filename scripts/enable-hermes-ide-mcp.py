"""Merge Hermes MCP servers into Cursor and VS Code user configs."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import sys

HERMES_MEMORY = "hermes-memory"
HERMES_TOOLS = "hermes-tools"
PLUGIN_NAME = "ai-os-hermes-worker"
LOCK_PATH = Path(__file__).resolve().parent / "hermes-install.lock.json"
LEGACY_CURSOR_RULE = Path("rules") / "hermes-worker.mdc"
PREVIOUS_AIOS_WORKER_BODIES = (
    """# Hermes Worker Instructions

These rules apply to Cursor and VS Code workers under a GPT/Codex Blueprint.

- For a non-trivial task, begin by calling `hermes_memory` with `action=read` and `target=all`. Use only memory relevant to the active repo and task.
- When prior work, an earlier decision, or a previous error may answer the request, call `hermes_session_search` with a narrow query before scanning chat history or large parts of a repository.
- Follow the GPT/Codex Blueprint. Do not change architecture, scope, or release.
- Before a task that matches a reusable workflow, call `skills_list` and load the relevant native Hermes `SKILL.md` with `skill_view`.
- Do not write Hermes memory that has not passed QA. Return `memory_candidates` to Codex instead of calling `hermes_memory` write actions.
- Never include credentials, tokens, private keys, raw logs, large code blocks, temporary paths, or unverified guesses in `memory_candidates`.
- Hermes native files and FTS5 remain the memory backend. Do not create a competing memory store, search engine, or session database.
""",
)


def plugin_version(lock_path: Path = LOCK_PATH) -> str:
    release = str(json.loads(lock_path.read_text(encoding="utf-8"))["ai_os_release"])
    return release[1:] if release.startswith(("v", "V")) else release


def plugin_manifest(lock_path: Path = LOCK_PATH) -> dict[str, str]:
    return {
        "name": PLUGIN_NAME,
        "description": "Hermes worker memory workflow for Cursor agents",
        "version": plugin_version(lock_path),
    }


def bridge_env(hermes_home: str) -> dict[str, str]:
    return {
        "HERMES_HOME": hermes_home,
        "HERMES_QUIET": "1",
        "HERMES_REDACT_SECRETS": "true",
    }


def hermes_servers(
    python_exe: str,
    memory_server: str,
    hermes_home: str,
    *,
    vscode: bool,
) -> dict[str, dict]:
    env = bridge_env(hermes_home)
    memory: dict = {
        "command": python_exe,
        "args": [memory_server],
        "env": dict(env),
    }
    tools: dict = {
        "command": python_exe,
        "args": ["-m", "agent.transports.hermes_tools_mcp_server"],
        "env": dict(env),
    }
    if vscode:
        memory = {"type": "stdio", **memory}
        tools = {"type": "stdio", **tools}
    return {HERMES_MEMORY: memory, HERMES_TOOLS: tools}


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8-sig")
    if not text.strip():
        return {}
    data = json.loads(text)
    if not isinstance(data, dict):
        raise ValueError(f"MCP config root must be an object: {path}")
    return data


def canonical_json(data: dict) -> str:
    return json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def normalize_text(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def backup_file(path: Path) -> Path | None:
    if not path.exists():
        return None
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup = path.with_name(f"{path.name}.{stamp}.bak")
    shutil.copy2(path, backup)
    return backup


def atomic_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(f"{path.name}.tmp")
    temp.write_text(text, encoding="utf-8", newline="\n")
    temp.replace(path)


def atomic_write_json(path: Path, data: dict) -> None:
    atomic_write_text(
        path, json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    )


def write_text_if_changed(path: Path, text: str) -> bool:
    if path.exists() and normalize_text(
        path.read_text(encoding="utf-8-sig")
    ) == normalize_text(text):
        return False
    backup_file(path)
    atomic_write_text(path, text)
    return True


def merge_mcp(path: Path, bucket_key: str, servers: dict) -> tuple[dict, bool]:
    current = load_json(path)
    desired = json.loads(json.dumps(current))
    bucket = desired.get(bucket_key)
    if bucket is None:
        bucket = {}
        desired[bucket_key] = bucket
    if not isinstance(bucket, dict):
        raise ValueError(f"{bucket_key} must be an object: {path}")
    for name, spec in servers.items():
        bucket[name] = spec
    if path.exists() and canonical_json(current) == canonical_json(desired):
        return desired, False
    backup_file(path)
    atomic_write_json(path, desired)
    return desired, True


def cursor_rule_text(body: str) -> str:
    return (
        "---\n"
        "description: Hermes worker memory workflow\n"
        "alwaysApply: true\n"
        "---\n\n"
        f"{body.rstrip()}\n"
    )


def vscode_instruction_text(body: str) -> str:
    return f"---\napplyTo: \"**\"\n---\n\n{body.rstrip()}\n"


def write_cursor_plugin(plugin_root: Path, body: str) -> dict[str, bool]:
    manifest_path = plugin_root / ".cursor-plugin" / "plugin.json"
    rule_path = plugin_root / "rules" / "hermes-worker.mdc"
    manifest_text = json.dumps(plugin_manifest(), indent=2, ensure_ascii=False) + "\n"
    return {
        "manifest": write_text_if_changed(manifest_path, manifest_text),
        "rule": write_text_if_changed(rule_path, cursor_rule_text(body)),
    }


def write_vscode_instructions(path: Path, body: str) -> bool:
    return write_text_if_changed(path, vscode_instruction_text(body))


def recognized_legacy_rule_texts(worker_body: str = "") -> list[str]:
    bodies = list(PREVIOUS_AIOS_WORKER_BODIES)
    if worker_body.strip():
        bodies.append(worker_body)
    return [normalize_text(cursor_rule_text(body)).strip() for body in bodies]


def is_recognized_legacy_rule(text: str, worker_body: str = "") -> bool:
    return normalize_text(text).strip() in set(recognized_legacy_rule_texts(worker_body))


def remove_legacy_cursor_rule(cursor_home: Path, worker_body: str = "") -> str:
    legacy = cursor_home / LEGACY_CURSOR_RULE
    if not legacy.exists():
        return "absent"
    content = legacy.read_text(encoding="utf-8-sig")
    if not is_recognized_legacy_rule(content, worker_body):
        return "preserved"
    backup_file(legacy)
    legacy.unlink()
    return "removed"


def preserved_names(data: dict, bucket_key: str) -> list[str]:
    bucket = data.get(bucket_key, {})
    if not isinstance(bucket, dict):
        return []
    return [name for name in bucket if name not in (HERMES_MEMORY, HERMES_TOOLS)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hermes-home", type=Path, required=True)
    parser.add_argument("--memory-server", type=Path, required=True)
    parser.add_argument("--cursor-mcp", type=Path)
    parser.add_argument("--vscode-mcp", type=Path)
    parser.add_argument("--cursor-home", type=Path)
    parser.add_argument("--cursor-plugin-root", type=Path)
    parser.add_argument("--vscode-instructions", type=Path)
    parser.add_argument("--worker-template", type=Path)
    parser.add_argument("--skip-cursor", action="store_true")
    parser.add_argument("--skip-vscode", action="store_true")
    args = parser.parse_args()

    hermes_home = str(args.hermes_home.expanduser().resolve())
    memory_server = str(args.memory_server.expanduser().resolve())
    python_exe = sys.executable
    worker_body = ""
    if args.worker_template is not None:
        worker_body = args.worker_template.read_text(encoding="utf-8")

    migrated: list[str] = []
    preserved: list[str] = []
    wrote: list[str] = []

    if not args.skip_cursor and args.cursor_mcp is not None:
        cursor_servers = hermes_servers(
            python_exe, memory_server, hermes_home, vscode=False
        )
        cursor_data, cursor_wrote = merge_mcp(
            args.cursor_mcp, "mcpServers", cursor_servers
        )
        migrated.extend(["cursor:hermes-memory", "cursor:hermes-tools"])
        preserved.extend(
            f"cursor:{name}" for name in preserved_names(cursor_data, "mcpServers")
        )
        if cursor_wrote:
            wrote.append("cursor-mcp")
        print(f"cursor={args.cursor_mcp}")
        if args.cursor_plugin_root is not None:
            if not worker_body:
                raise ValueError("Worker template is required for Cursor plugin rules.")
            plugin_wrote = write_cursor_plugin(args.cursor_plugin_root, worker_body)
            print(f"cursor_plugin={args.cursor_plugin_root}")
            if plugin_wrote["manifest"]:
                wrote.append("cursor-plugin-manifest")
            if plugin_wrote["rule"]:
                wrote.append("cursor-plugin-rule")
        if args.cursor_home is not None:
            legacy_status = remove_legacy_cursor_rule(args.cursor_home, worker_body)
            print(f"legacy_rule={legacy_status}")
            if legacy_status == "removed":
                wrote.append("cursor-legacy-rule-removed")
            elif legacy_status == "preserved":
                preserved.append("cursor:legacy-rule-preserved")

    if not args.skip_vscode and args.vscode_mcp is not None:
        vscode_servers = hermes_servers(
            python_exe, memory_server, hermes_home, vscode=True
        )
        vscode_data, vscode_wrote = merge_mcp(
            args.vscode_mcp, "servers", vscode_servers
        )
        migrated.extend(["vscode:hermes-memory", "vscode:hermes-tools"])
        preserved.extend(
            f"vscode:{name}" for name in preserved_names(vscode_data, "servers")
        )
        if vscode_wrote:
            wrote.append("vscode-mcp")
        print(f"vscode={args.vscode_mcp}")
        if args.vscode_instructions is not None:
            if not worker_body:
                raise ValueError("Worker template is required for VS Code instructions.")
            if write_vscode_instructions(args.vscode_instructions, worker_body):
                wrote.append("vscode-instructions")
            print(f"vscode_instructions={args.vscode_instructions}")

    print(f"migrated={','.join(migrated)}")
    print(f"preserved={','.join(preserved)}")
    print(f"wrote={','.join(wrote)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
