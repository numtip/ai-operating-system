"""Expose Hermes' native local tool surface to Codex through MCP."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys

from hermes_cli.codex_runtime_plugin_migration import migrate


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--codex-home", type=Path, required=True)
    parser.add_argument("--hermes-home", type=Path, required=True)
    parser.add_argument("--memory-server", type=Path, required=True)
    args = parser.parse_args()

    hermes_home = str(args.hermes_home.expanduser().resolve())
    os.environ["HERMES_HOME"] = hermes_home
    bridge_env = {
        "HERMES_HOME": hermes_home,
        "HERMES_QUIET": "1",
        "HERMES_REDACT_SECRETS": "true",
    }
    hermes_config = {
        "mcp_servers": {
            "hermes-memory": {
                "command": sys.executable,
                "args": [str(args.memory_server.resolve())],
                "env": bridge_env,
                "connect_timeout": 30,
                "timeout": 600,
            }
        }
    }

    report = migrate(
        hermes_config,
        codex_home=args.codex_home,
        dry_run=False,
        discover_plugins=False,
        default_permission_profile=None,
        expose_hermes_tools=True,
    )
    print(f"target={report.target_path}")
    print(f"migrated={','.join(report.migrated)}")
    print(f"errors={' | '.join(report.errors)}")
    return 1 if report.errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
