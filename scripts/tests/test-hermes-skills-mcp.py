"""Protocol-level verification of Hermes' native SKILL.md MCP surface."""

from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


def first_text(result) -> str:
    blocks = [block.text for block in result.content if hasattr(block, "text")]
    if not blocks:
        raise RuntimeError("MCP result contained no text block")
    return blocks[0]


async def run(python_exe: Path, hermes_home: Path) -> int:
    params = StdioServerParameters(
        command=str(python_exe),
        args=["-m", "agent.transports.hermes_tools_mcp_server"],
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

            ok = "hermes-agent" in catalog_names and set(loaded) == {
                "hermes-agent",
                "obsidian",
            }
            print(
                json.dumps(
                    {
                        "success": ok,
                        "tools": ["skill_view", "skills_list"],
                        "loaded": loaded,
                    }
                )
            )
            return 0 if ok else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--python", type=Path, required=True)
    parser.add_argument("--hermes-home", type=Path, required=True)
    args = parser.parse_args()
    return asyncio.run(run(args.python, args.hermes_home))


if __name__ == "__main__":
    raise SystemExit(main())
