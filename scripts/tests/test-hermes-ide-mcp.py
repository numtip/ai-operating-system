"""Portable schema and merge tests for Cursor/VS Code Hermes MCP adapters."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import time
import unittest


HELPER = Path(__file__).resolve().parents[1] / "enable-hermes-ide-mcp.py"
LOCK = Path(__file__).resolve().parents[1] / "hermes-install.lock.json"
WORKER = (
    Path(__file__).resolve().parents[2]
    / "06_Research"
    / "pilots"
    / "v1.6-hermes"
    / "obsidian-vault"
    / "GLOBAL_AGENTS_HERMES_WORKER.md"
)


def load_helper():
    spec = importlib.util.spec_from_file_location("enable_hermes_ide_mcp", HELPER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load helper: {HELPER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


helper = load_helper()


class HermesIdeMcpTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.python = str(self.root / "python.exe")
        self.memory_server = str(self.root / "hermes-memory-mcp-server.py")
        self.hermes_home = str(self.root / "hermes")
        self.worker_body = WORKER.read_text(encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_cursor_schema_omits_type(self) -> None:
        servers = helper.hermes_servers(
            self.python, self.memory_server, self.hermes_home, vscode=False
        )
        self.assertEqual(set(servers), {"hermes-memory", "hermes-tools"})
        self.assertNotIn("type", servers["hermes-memory"])
        self.assertEqual(servers["hermes-memory"]["command"], self.python)
        self.assertEqual(servers["hermes-memory"]["args"], [self.memory_server])
        self.assertEqual(
            servers["hermes-tools"]["args"],
            ["-m", "agent.transports.hermes_tools_mcp_server"],
        )
        self.assertEqual(
            servers["hermes-memory"]["env"],
            {
                "HERMES_HOME": self.hermes_home,
                "HERMES_QUIET": "1",
                "HERMES_REDACT_SECRETS": "true",
            },
        )

    def test_vscode_schema_requires_stdio_type(self) -> None:
        servers = helper.hermes_servers(
            self.python, self.memory_server, self.hermes_home, vscode=True
        )
        self.assertEqual(servers["hermes-memory"]["type"], "stdio")
        self.assertEqual(servers["hermes-tools"]["type"], "stdio")
        self.assertEqual(servers["hermes-tools"]["command"], self.python)

    def test_cursor_merge_preserves_magnific_and_is_idempotent(self) -> None:
        path = self.root / "cursor" / "mcp.json"
        path.parent.mkdir(parents=True)
        original = {
            "mcpServers": {
                "magnific": {"url": "https://mcp.magnific.com"},
                "other": {"command": "keep-me", "args": ["--safe"]},
            }
        }
        path.write_text(json.dumps(original, indent=2) + "\n", encoding="utf-8")
        servers = helper.hermes_servers(
            self.python, self.memory_server, self.hermes_home, vscode=False
        )
        first, first_wrote = helper.merge_mcp(path, "mcpServers", servers)
        self.assertTrue(first_wrote)
        backups_after_first = list(path.parent.glob("mcp.json.*.bak"))
        self.assertEqual(len(backups_after_first), 1)
        first_mtime = path.stat().st_mtime
        time.sleep(1.1)
        second, second_wrote = helper.merge_mcp(path, "mcpServers", servers)
        self.assertFalse(second_wrote)
        names = list(second["mcpServers"])
        self.assertEqual(names.count("hermes-memory"), 1)
        self.assertEqual(names.count("hermes-tools"), 1)
        self.assertEqual(names.count("magnific"), 1)
        self.assertEqual(
            second["mcpServers"]["magnific"], {"url": "https://mcp.magnific.com"}
        )
        self.assertEqual(
            second["mcpServers"]["other"],
            {"command": "keep-me", "args": ["--safe"]},
        )
        self.assertEqual(
            first["mcpServers"]["hermes-memory"],
            second["mcpServers"]["hermes-memory"],
        )
        self.assertEqual(len(list(path.parent.glob("mcp.json.*.bak"))), 1)
        self.assertEqual(path.stat().st_mtime, first_mtime)

    def test_vscode_merge_preserves_inputs_and_existing_servers(self) -> None:
        path = self.root / "vscode" / "mcp.json"
        path.parent.mkdir(parents=True)
        original = {
            "inputs": [{"id": "token", "type": "promptString"}],
            "servers": {
                "magnific": {"type": "http", "url": "https://mcp.magnific.com"},
            },
        }
        path.write_text(json.dumps(original, indent=2) + "\n", encoding="utf-8")
        servers = helper.hermes_servers(
            self.python, self.memory_server, self.hermes_home, vscode=True
        )
        merged, first_wrote = helper.merge_mcp(path, "servers", servers)
        self.assertTrue(first_wrote)
        first_mtime = path.stat().st_mtime
        time.sleep(1.1)
        _, second_wrote = helper.merge_mcp(path, "servers", servers)
        self.assertFalse(second_wrote)
        reloaded = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(reloaded["inputs"], original["inputs"])
        self.assertEqual(
            reloaded["servers"]["magnific"],
            {"type": "http", "url": "https://mcp.magnific.com"},
        )
        self.assertEqual(reloaded["servers"]["hermes-memory"]["type"], "stdio")
        self.assertEqual(
            len([name for name in reloaded["servers"] if name.startswith("hermes-")]),
            2,
        )
        self.assertIn("servers", merged)
        self.assertEqual(len(list(path.parent.glob("mcp.json.*.bak"))), 1)
        self.assertEqual(path.stat().st_mtime, first_mtime)

    def test_invalid_json_does_not_clobber(self) -> None:
        path = self.root / "broken.json"
        path.write_text("{not-json", encoding="utf-8")
        with self.assertRaises(json.JSONDecodeError):
            helper.merge_mcp(
                path,
                "mcpServers",
                helper.hermes_servers(
                    self.python, self.memory_server, self.hermes_home, vscode=False
                ),
            )
        self.assertEqual(path.read_text(encoding="utf-8"), "{not-json")

    def test_cursor_plugin_layout_and_idempotent_rule(self) -> None:
        plugin_root = self.root / "cursor" / "plugins" / "local" / "ai-os-hermes-worker"
        wrote = helper.write_cursor_plugin(plugin_root, self.worker_body)
        self.assertTrue(wrote["manifest"])
        self.assertTrue(wrote["rule"])
        manifest = json.loads(
            (plugin_root / ".cursor-plugin" / "plugin.json").read_text(encoding="utf-8")
        )
        rule = (plugin_root / "rules" / "hermes-worker.mdc").read_text(encoding="utf-8")
        self.assertEqual(manifest["name"], "ai-os-hermes-worker")
        lock_release = json.loads(LOCK.read_text(encoding="utf-8"))["ai_os_release"]
        expected_version = lock_release[1:] if lock_release.startswith("v") else lock_release
        self.assertEqual(manifest["version"], expected_version)
        self.assertEqual(helper.plugin_version(), expected_version)
        self.assertEqual(expected_version, "1.6.0-alpha.2")
        self.assertIn("alwaysApply: true", rule)
        self.assertIn("never write durable Hermes memory", rule)
        self.assertIn("memory_candidates", rule)
        rule_mtime = (plugin_root / "rules" / "hermes-worker.mdc").stat().st_mtime
        time.sleep(1.1)
        second = helper.write_cursor_plugin(plugin_root, self.worker_body)
        self.assertFalse(second["manifest"])
        self.assertFalse(second["rule"])
        self.assertEqual(
            (plugin_root / "rules" / "hermes-worker.mdc").stat().st_mtime, rule_mtime
        )
        self.assertEqual(len(list((plugin_root / "rules").glob("hermes-worker.mdc.*.bak"))), 0)
        self.assertFalse((self.root / "cursor" / "rules" / "hermes-worker.mdc").exists())

    def test_recognized_legacy_rule_is_removed(self) -> None:
        cursor_home = self.root / "cursor"
        legacy = cursor_home / "rules" / "hermes-worker.mdc"
        legacy.parent.mkdir(parents=True)
        legacy.write_text(helper.cursor_rule_text(self.worker_body), encoding="utf-8")
        self.assertEqual(helper.remove_legacy_cursor_rule(cursor_home, self.worker_body), "removed")
        self.assertFalse(legacy.exists())
        self.assertEqual(len(list(legacy.parent.glob("hermes-worker.mdc.*.bak"))), 1)
        self.assertEqual(helper.remove_legacy_cursor_rule(cursor_home, self.worker_body), "absent")

    def test_previous_aios_legacy_rule_is_removed(self) -> None:
        cursor_home = self.root / "cursor"
        legacy = cursor_home / "rules" / "hermes-worker.mdc"
        legacy.parent.mkdir(parents=True)
        legacy.write_text(
            helper.cursor_rule_text(helper.PREVIOUS_AIOS_WORKER_BODIES[0]),
            encoding="utf-8",
        )
        self.assertEqual(helper.remove_legacy_cursor_rule(cursor_home, self.worker_body), "removed")
        self.assertFalse(legacy.exists())

    def test_customized_legacy_rule_is_preserved(self) -> None:
        cursor_home = self.root / "cursor"
        legacy = cursor_home / "rules" / "hermes-worker.mdc"
        legacy.parent.mkdir(parents=True)
        customized = helper.cursor_rule_text(self.worker_body) + "\n# user note\n"
        legacy.write_text(customized, encoding="utf-8")
        self.assertEqual(
            helper.remove_legacy_cursor_rule(cursor_home, self.worker_body), "preserved"
        )
        self.assertTrue(legacy.exists())
        self.assertEqual(legacy.read_text(encoding="utf-8"), customized)
        self.assertEqual(len(list(legacy.parent.glob("hermes-worker.mdc.*.bak"))), 0)

    def test_worker_rule_is_unconditional(self) -> None:
        self.assertIn("never write durable Hermes memory", self.worker_body)
        self.assertIn("GPT/Codex", self.worker_body)
        self.assertNotIn("that has not passed QA", self.worker_body)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    raise SystemExit(0 if result.wasSuccessful() else 1)
