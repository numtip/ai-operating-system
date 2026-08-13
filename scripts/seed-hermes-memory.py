"""Seed the native Hermes memory store with the owner's operating decision."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from tools.memory_tool import MemoryStore, memory_tool


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--projects-root", type=Path, required=True)
    parser.add_argument("--hermes-home", type=Path, required=True)
    parser.add_argument("--user-preference", default="")
    args = parser.parse_args()

    store = MemoryStore()
    store.load_from_disk()
    entries = [
        (
            "memory",
            f"Project repos under {args.projects_root.resolve()} use Hermes native "
            f"persistent memory and session_search. Hermes home is "
            f"{args.hermes_home.resolve()}; Obsidian opens that same native home. "
            "Do not build a competing memory system.",
        )
    ]
    if args.user_preference.strip():
        entries.append(("user", args.user_preference.strip()))

    for target, content in entries:
        existing = (
            store.memory_entries if target == "memory" else store.user_entries
        )
        if content in existing:
            print(json.dumps({"success": True, "skipped": "already-present"}))
            continue
        result = json.loads(
            memory_tool(action="add", target=target, content=content, store=store)
        )
        print(json.dumps(result, ensure_ascii=False))
        if not result.get("success"):
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
