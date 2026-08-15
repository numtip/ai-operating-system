"""Expose Hermes' native memory and FTS5 session search to Codex via MCP.

This is an integration bridge only. Storage, limits, security scanning, and
search behavior remain owned by the installed Hermes Agent implementation.
"""

from __future__ import annotations

import json

from mcp.server.fastmcp import FastMCP


mcp = FastMCP(
    "hermes-memory",
    instructions=(
        "Shared memory for every project repo. At the start of a non-trivial "
        "task, read Hermes memory. Search past Hermes sessions before broad "
        "history or repository scans when prior work may answer the question. "
        "At task close, save only durable facts, decisions, corrections, and "
        "user preferences. Never save secrets, raw logs, or temporary state."
    ),
)


@mcp.tool()
def hermes_memory(
    action: str = "read",
    target: str = "all",
    content: str = "",
    old_text: str = "",
) -> str:
    """Read or update native Hermes MEMORY.md and USER.md.

    Use action=read with target=all|memory|user. For writes, use
    action=add|replace|remove and target=memory|user. Replace/remove require a
    short unique old_text. Hermes enforces its native limits and security scan.
    """
    from tools.memory_tool import MemoryStore, memory_tool

    store = MemoryStore()
    store.load_from_disk()

    if action == "read":
        if target not in {"all", "memory", "user"}:
            return json.dumps(
                {"success": False, "error": "target must be all, memory, or user"},
                ensure_ascii=False,
            )
        payload = {"success": True, "target": target}
        if target in {"all", "memory"}:
            payload["memory"] = {
                "entries": store.memory_entries,
                "usage": f"{store._char_count('memory')}/{store.memory_char_limit}",
            }
        if target in {"all", "user"}:
            payload["user"] = {
                "entries": store.user_entries,
                "usage": f"{store._char_count('user')}/{store.user_char_limit}",
            }
        return json.dumps(payload, ensure_ascii=False)

    if target not in {"memory", "user"}:
        return json.dumps(
            {"success": False, "error": "write target must be memory or user"},
            ensure_ascii=False,
        )
    return memory_tool(
        action=action,
        target=target,
        content=content or None,
        old_text=old_text or None,
        store=store,
    )


@mcp.tool()
def hermes_session_search(
    query: str = "",
    limit: int = 3,
    session_id: str = "",
    around_message_id: int = 0,
    window: int = 5,
    sort: str = "",
) -> str:
    """Search, browse, or read native Hermes sessions with zero LLM calls.

    Pass query for FTS5 discovery; no arguments to browse recent sessions;
    session_id to read one session; or session_id plus around_message_id to
    scroll around a message.
    """
    from hermes_state import SessionDB
    from tools.session_search_tool import session_search

    db = SessionDB()
    try:
        return session_search(
            query=query,
            limit=limit,
            db=db,
            session_id=session_id or None,
            around_message_id=around_message_id or None,
            window=window,
            sort=sort or None,
        )
    finally:
        db.close()


if __name__ == "__main__":
    mcp.run()
