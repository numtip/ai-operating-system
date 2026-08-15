"""Protocol-level smoke test for the Hermes native-memory MCP bridge."""

from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def run(python_exe: Path, server_script: Path, hermes_home: Path) -> int:
    params = StdioServerParameters(
        command=str(python_exe),
        args=[str(server_script)],
        env={
            "HERMES_HOME": str(hermes_home),
            "HERMES_QUIET": "1",
            "HERMES_REDACT_SECRETS": "true",
        },
    )
    async with stdio_client(params) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()
            listed = await session.list_tools()
            tool_names = sorted(tool.name for tool in listed.tools)
            expected = ["hermes_memory", "hermes_session_search"]
            if tool_names != expected:
                print(json.dumps({"success": False, "tools": tool_names}))
                return 1

            result = await session.call_tool(
                "hermes_memory", {"action": "read", "target": "all"}
            )
            text_blocks = [block.text for block in result.content if hasattr(block, "text")]
            payload = json.loads(text_blocks[0])
            ok = bool(payload.get("success") and payload.get("memory") and payload.get("user"))
            print(json.dumps({"success": ok, "tools": tool_names}, ensure_ascii=False))
            return 0 if ok else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--python", type=Path, required=True)
    parser.add_argument("--server", type=Path, required=True)
    parser.add_argument("--hermes-home", type=Path, required=True)
    args = parser.parse_args()
    return asyncio.run(run(args.python, args.server, args.hermes_home))


if __name__ == "__main__":
    raise SystemExit(main())
