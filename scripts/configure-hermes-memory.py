"""Merge the AI-OS memory settings into an existing Hermes config safely."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path
import shutil

from ruamel.yaml import YAML


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hermes-home", type=Path, required=True)
    args = parser.parse_args()

    home = args.hermes_home.expanduser().resolve()
    home.mkdir(parents=True, exist_ok=True)
    config_path = home / "config.yaml"
    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)

    data: dict = {}
    if config_path.exists():
        loaded = yaml.load(config_path.read_text(encoding="utf-8"))
        if loaded is not None:
            if not isinstance(loaded, dict):
                raise ValueError("Hermes config.yaml root must be a mapping")
            data = loaded
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        shutil.copy2(config_path, config_path.with_name(f"config.yaml.{stamp}.bak"))

    memory = data.setdefault("memory", {})
    display = data.setdefault("display", {})
    if not isinstance(memory, dict) or not isinstance(display, dict):
        raise ValueError("Hermes memory/display config sections must be mappings")

    memory["memory_enabled"] = True
    memory["user_profile_enabled"] = True
    memory["write_approval"] = False
    display["memory_notifications"] = "verbose"

    temp_path = config_path.with_suffix(".yaml.tmp")
    with temp_path.open("w", encoding="utf-8", newline="\n") as handle:
        yaml.dump(data, handle)
    temp_path.replace(config_path)
    print(config_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
