"""Offline protocol verification of Hermes' native SKILL.md MCP surface."""

from __future__ import annotations

import argparse
import ast
import asyncio
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import unittest

FORBIDDEN_LOGS = ("PAID lane", "provider auth", "external request")
SITECUSTOMIZE_SRC = Path(__file__).resolve().parent / "offline_sitecustomize.py"
ENV_ALLOWLIST = {
    "PATH",
    "PATHEXT",
    "SYSTEMROOT",
    "WINDIR",
    "SYSTEMDRIVE",
    "COMSPEC",
    "TEMP",
    "TMP",
    "OS",
    "PROCESSOR_ARCHITECTURE",
    "NUMBER_OF_PROCESSORS",
    "PYTHONPATH",
    "PYTHONHOME",
    "PYTHONUTF8",
    "PYTHONIOENCODING",
    "PYTHONNOUSERSITE",
}
DENY_SUFFIXES = ("_KEY", "_TOKEN", "_SECRET")
DENY_NAME_MARKERS = (
    "OAUTH",
    "BASE_URL",
    "API_BASE",
    "API_URL",
    "PROVIDER",
    "OPENROUTER",
    "ANTHROPIC",
    "OPENAI",
    "NOUS",
)
SMOKE_ENV = {
    "HERMES_QUIET": "1",
    "HERMES_REDACT_SECRETS": "true",
    "HERMES_DISABLE_LAZY_INSTALLS": "1",
    "AWS_EC2_METADATA_DISABLED": "true",
    "PYTHONNOUSERSITE": "1",
}
GUARD_PROBE = (
    "import json, os, socket; "
    "print(json.dumps({"
    "'netguard': os.environ.get('HERMES_SKILLS_SMOKE_NETGUARD'), "
    "'getaddrinfo_denied': bool(getattr(socket.getaddrinfo, '_hermes_smoke_denied', False)), "
    "'sendto_denied': bool(getattr(socket.socket.sendto, '_hermes_smoke_denied', False)), "
    "'sendmsg_denied': bool(getattr(getattr(socket.socket, 'sendmsg', object()), '_hermes_smoke_denied', False))"
    "}))"
)
DENY_PROBE_CALLS = (
    ("getaddrinfo", "socket.getaddrinfo('example.com', 443)"),
    ("create_connection", "socket.create_connection(('example.com', 443), 1)"),
    ("connect", "socket.socket().connect(('example.com', 443))"),
    ("connect_ex", "socket.socket().connect_ex(('example.com', 443))"),
    ("sendto", "socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendto(b'x', ('example.com', 53))"),
)
if hasattr(socket.socket, "sendmsg"):
    DENY_PROBE_CALLS = DENY_PROBE_CALLS + (
        (
            "sendmsg",
            "socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendmsg([b'x'], [], 0, ('example.com', 53))",
        ),
    )


def load_mcp_client():
    """Import MCP client pieces only for the live protocol path."""
    try:
        from mcp import ClientSession, StdioServerParameters
        from mcp.client.stdio import stdio_client
    except ImportError as exc:
        raise SystemExit(
            "The mcp package is required for live skills protocol smoke."
        ) from exc
    return ClientSession, StdioServerParameters, stdio_client


def first_text(result) -> str:
    blocks = [block.text for block in result.content if hasattr(block, "text")]
    if not blocks:
        raise RuntimeError("MCP result contained no text block")
    return blocks[0]


def denied_env_name(name: str) -> bool:
    upper = name.upper()
    if upper.endswith(DENY_SUFFIXES):
        return True
    return any(marker in upper for marker in DENY_NAME_MARKERS)


def offline_env(hermes_home: Path, pythonpath: Path, deny_log: Path | None = None) -> dict[str, str]:
    env: dict[str, str] = {}
    for key in ENV_ALLOWLIST:
        value = os.environ.get(key)
        if value and not denied_env_name(key):
            env[key] = value
    env.update(SMOKE_ENV)
    env["HERMES_HOME"] = str(hermes_home)
    env["PYTHONPATH"] = str(pythonpath)
    if deny_log is not None:
        env["HERMES_SKILLS_SMOKE_DENY_LOG"] = str(deny_log)
    return env


def write_offline_config(home: Path) -> None:
    home.mkdir(parents=True, exist_ok=True)
    (home / "config.yaml").write_text(
        "\n".join(
            [
                "model:",
                "  context_length: 8192",
                "tools:",
                "  tool_search:",
                '    enabled: "off"',
                "auxiliary:",
                "  free_only: true",
                "logging:",
                "  level: WARNING",
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )


def prepare_isolated_home(source_home: Path) -> Path:
    isolated = Path(tempfile.mkdtemp(prefix="hermes-skills-smoke-"))
    write_offline_config(isolated)
    source_skills = source_home / "skills"
    if source_skills.is_dir():
        shutil.copytree(source_skills, isolated / "skills")
    return isolated


def install_sitecustomize(directory: Path) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / "sitecustomize.py"
    shutil.copy2(SITECUSTOMIZE_SRC, target)
    return target


def network_guard_active() -> bool:
    sendmsg_ok = not hasattr(socket.socket, "sendmsg") or bool(
        getattr(socket.socket.sendmsg, "_hermes_smoke_denied", False)
    )
    return os.environ.get("HERMES_SKILLS_SMOKE_NETGUARD") == "1" and bool(
        getattr(socket.getaddrinfo, "_hermes_smoke_denied", False)
        and getattr(socket.socket.sendto, "_hermes_smoke_denied", False)
        and sendmsg_ok
    )


def read_deny_log(path: Path) -> list[str]:
    if not path.exists():
        return []
    return [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def assert_deny_log_empty(path: Path, *, context: str) -> None:
    entries = read_deny_log(path)
    if entries:
        raise RuntimeError(f"{context}: deny.log not empty: {entries}")


def probe_guard(python_exe: Path, env: dict[str, str]) -> dict:
    result = subprocess.run(
        [str(python_exe), "-c", GUARD_PROBE],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr or result.stdout or "guard probe failed")
    payload = json.loads(result.stdout or "{}")
    payload["active"] = (
        payload.get("netguard") == "1"
        and payload.get("getaddrinfo_denied")
        and payload.get("sendto_denied")
        and (
            not hasattr(socket.socket, "sendmsg")
            or payload.get("sendmsg_denied")
        )
    )
    return payload


def fail_on_forbidden(text: str) -> None:
    for token in FORBIDDEN_LOGS:
        if token in text:
            raise RuntimeError(f"Zero-network smoke saw forbidden log: {token}")


async def run(python_exe: Path, hermes_home: Path, pythonpath: Path, deny_log: Path) -> int:
    if not network_guard_active():
        print(json.dumps({"success": False, "error": "runner network guard inactive"}))
        return 1

    server_env = offline_env(hermes_home, pythonpath, deny_log)
    server_guard = probe_guard(python_exe, server_env)
    if not server_guard.get("active"):
        print(
            json.dumps(
                {
                    "success": False,
                    "error": "mcp server network guard inactive",
                    "server_guard": server_guard,
                }
            )
        )
        return 1

    ClientSession, StdioServerParameters, stdio_client = load_mcp_client()
    params = StdioServerParameters(
        command=str(python_exe),
        args=["-m", "agent.transports.hermes_tools_mcp_server"],
        env=server_env,
    )
    async with stdio_client(params) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()
            listed = await session.list_tools()
            tool_names = {tool.name for tool in listed.tools}
            if not {"skills_list", "skill_view"}.issubset(tool_names):
                print(json.dumps({"success": False, "tools": sorted(tool_names)}))
                return 1

            catalog = json.loads(
                first_text(
                    await session.call_tool(
                        "skills_list", {"category": "autonomous-ai-agents"}
                    )
                )
            )
            catalog_names = {item["name"] for item in catalog.get("skills", [])}

            loaded: list[str] = []
            for skill_name in ("hermes-agent", "obsidian"):
                payload = json.loads(
                    first_text(
                        await session.call_tool("skill_view", {"name": skill_name})
                    )
                )
                if not payload.get("success") or not payload.get(
                    "content", ""
                ).lstrip().startswith("---"):
                    print(json.dumps({"success": False, "skill": skill_name}))
                    return 1
                loaded.append(skill_name)

            try:
                assert_deny_log_empty(deny_log, context="skills smoke")
            except RuntimeError as exc:
                print(json.dumps({"success": False, "error": str(exc)}))
                return 1

            ok = (
                network_guard_active()
                and server_guard.get("active")
                and "hermes-agent" in catalog_names
                and set(loaded) == {"hermes-agent", "obsidian"}
            )
            print(
                json.dumps(
                    {
                        "success": ok,
                        "tools": ["skill_view", "skills_list"],
                        "loaded": loaded,
                        "offline": ok,
                        "network_guard": True,
                        "runner_guard": True,
                        "server_guard": server_guard,
                        "deny_log": [],
                    }
                )
            )
            return 0 if ok else 1


def run_offline(python_exe: Path, source_home: Path) -> int:
    isolated = prepare_isolated_home(source_home)
    site_dir = Path(tempfile.mkdtemp(prefix="hermes-smoke-site-"))
    deny_log = site_dir / "deny.log"
    try:
        install_sitecustomize(site_dir)
        env = offline_env(isolated, site_dir, deny_log)
        result = subprocess.run(
            [
                str(python_exe),
                str(Path(__file__).resolve()),
                "--python",
                str(python_exe),
                "--hermes-home",
                str(isolated),
                "--inner",
                "--pythonpath",
                str(site_dir),
                "--deny-log",
                str(deny_log),
            ],
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )
        combined = (result.stdout or "") + (result.stderr or "")
        try:
            fail_on_forbidden(combined)
            assert_deny_log_empty(deny_log, context="offline wrapper")
        except RuntimeError as exc:
            print(json.dumps({"success": False, "error": str(exc)}))
            return 1
        if result.stdout:
            sys.stdout.write(result.stdout)
        if result.returncode != 0:
            if result.stderr:
                sys.stderr.write(result.stderr)
            return result.returncode
        return 0
    finally:
        shutil.rmtree(isolated, ignore_errors=True)
        shutil.rmtree(site_dir, ignore_errors=True)


def run_deny_probe(python_exe: Path) -> int:
    site_dir = Path(tempfile.mkdtemp(prefix="hermes-smoke-deny-"))
    deny_log = site_dir / "deny.log"
    seeded = {
        "GOOGLE_API_KEY": "seed-google-key",
        "CUSTOM_SMOKE_TOKEN": "seed-custom-token",
        "OPENROUTER_BASE_URL": "https://openrouter.example",
        "OAUTH_CLIENT_SECRET": "seed-oauth-secret",
    }
    previous = {key: os.environ.get(key) for key in seeded}
    try:
        install_sitecustomize(site_dir)
        os.environ.update(seeded)
        env = offline_env(site_dir / "hermes", site_dir, deny_log)
        leaked = [name for name in seeded if name in env]
        probe_lines = ["import json, socket", "blocked = {}"]
        for name, call in DENY_PROBE_CALLS:
            probe_lines.extend(
                [
                    "try:",
                    f"    {call}",
                    f"    blocked[{name!r}] = 'NOT_BLOCKED'",
                    "except Exception as exc:",
                    f"    blocked[{name!r}] = type(exc).__name__",
                ]
            )
        probe_lines.append("print(json.dumps(blocked))")
        probe = "\n".join(probe_lines)
        result = subprocess.run(
            [str(python_exe), "-c", probe],
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )
        blocked = json.loads(result.stdout or "{}")
        deny_names = read_deny_log(deny_log)
        expected = {name for name, _ in DENY_PROBE_CALLS}
        ok = (
            not leaked
            and set(blocked) == expected
            and all(value == "NetworkDenied" for value in blocked.values())
            and set(deny_names) >= expected
        )
        print(
            json.dumps(
                {
                    "success": ok,
                    "offline": ok,
                    "network_guard": True,
                    "leaked": leaked,
                    "blocked": blocked,
                    "deny_log": deny_names,
                    "parent_seeded": sorted(seeded),
                }
            )
        )
        return 0 if ok else 1
    finally:
        for key, value in previous.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        shutil.rmtree(site_dir, ignore_errors=True)


class HermesSkillsOfflineTests(unittest.TestCase):
    def test_env_scrub_drops_keys_tokens_secrets_and_provider_urls(self) -> None:
        previous = {
            key: os.environ.get(key)
            for key in (
                "GOOGLE_API_KEY",
                "CUSTOM_SMOKE_TOKEN",
                "OPENROUTER_BASE_URL",
                "OAUTH_CLIENT_SECRET",
                "PATH",
            )
        }
        os.environ["GOOGLE_API_KEY"] = "seed-google-key"
        os.environ["CUSTOM_SMOKE_TOKEN"] = "seed-custom-token"
        os.environ["OPENROUTER_BASE_URL"] = "https://openrouter.example"
        os.environ["OAUTH_CLIENT_SECRET"] = "seed-oauth-secret"
        try:
            env = offline_env(Path("hermes-home"), Path("site"))
            self.assertIn("PATH", env)
            self.assertNotIn("GOOGLE_API_KEY", env)
            self.assertNotIn("CUSTOM_SMOKE_TOKEN", env)
            self.assertNotIn("OPENROUTER_BASE_URL", env)
            self.assertNotIn("OAUTH_CLIENT_SECRET", env)
            self.assertTrue(all(not denied_env_name(name) or name in SMOKE_ENV for name in env))
        finally:
            for key, value in previous.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

    def test_network_guard_blocks_socket_dns_and_udp_without_request(self) -> None:
        python_exe = Path(sys.executable)
        self.assertEqual(run_deny_probe(python_exe), 0)

    def test_mcp_is_not_imported_at_module_level(self) -> None:
        tree = ast.parse(Path(__file__).read_text(encoding="utf-8"))
        for node in tree.body:
            if isinstance(node, ast.Import):
                self.assertFalse(
                    any(
                        alias.name == "mcp" or alias.name.startswith("mcp.")
                        for alias in node.names
                    ),
                    "mcp must not be imported at module load",
                )
            if isinstance(node, ast.ImportFrom):
                self.assertFalse(
                    (node.module or "").startswith("mcp"),
                    "mcp must not be imported at module load",
                )

    def test_smoke_fails_when_deny_log_not_empty(self) -> None:
        site_dir = Path(tempfile.mkdtemp(prefix="hermes-smoke-denyfail-"))
        deny_log = site_dir / "deny.log"
        try:
            deny_log.write_text("connect\n", encoding="utf-8")
            with self.assertRaises(RuntimeError):
                assert_deny_log_empty(deny_log, context="unit test")
        finally:
            shutil.rmtree(site_dir, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--python", type=Path)
    parser.add_argument("--hermes-home", type=Path)
    parser.add_argument("--pythonpath", type=Path)
    parser.add_argument("--deny-log", type=Path)
    parser.add_argument("--inner", action="store_true")
    parser.add_argument("--deny-probe", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromName(
            "HermesSkillsOfflineTests", module=sys.modules[__name__]
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1
    if args.deny_probe:
        if args.python is None:
            raise SystemExit("--python is required for --deny-probe")
        return run_deny_probe(args.python)
    if args.inner:
        if args.python is None or args.hermes_home is None or args.pythonpath is None or args.deny_log is None:
            raise SystemExit("--inner requires --python --hermes-home --pythonpath --deny-log")
        return asyncio.run(run(args.python, args.hermes_home, args.pythonpath, args.deny_log))
    if args.python is None or args.hermes_home is None:
        raise SystemExit("--python and --hermes-home are required")
    return run_offline(args.python, args.hermes_home)


if __name__ == "__main__":
    raise SystemExit(main())
