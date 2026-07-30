#!/usr/bin/env bash
# Validates required folders and memory/governance files for AI Operating System v1.
# Run from repo root: bash scripts/validate-structure.sh
# Exit 0 on pass, 1 on fail. Prints PASS/FAIL per check.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0

check_dir() {
  local rel="$1"
  if [[ -d "$ROOT/$rel" ]]; then
    echo "PASS  [Directory] $rel"
  else
    echo "FAIL  [Directory] $rel"
    failed=$((failed + 1))
  fi
}

check_file() {
  local rel="$1"
  if [[ -f "$ROOT/$rel" ]]; then
    echo "PASS  [File] $rel"
  else
    echo "FAIL  [File] $rel"
    failed=$((failed + 1))
  fi
}

required_folders=(
  00_Dashboard
  01_Projects
  02_Knowledge
  03_Architecture
  04_ADR
  05_Meetings
  06_Research
  07_Memory
  08_Skills
  09_SOP
  10_Releases
  11_Templates
  Archive
  scripts
)

required_files=(
  README.md
  07_Memory/OPERATING_RULES.md
  07_Memory/SYSTEM_MEMORY.md
  07_Memory/CURRENT_STATE.md
  07_Memory/SESSION_INDEX.md
  07_Memory/DECISION_MEMORY.md
  07_Memory/SESSION_BOOTSTRAP.md
  07_Memory/SESSION_CLOSE.md
  04_ADR/ADR-TEMPLATE.md
  04_ADR/ADR-0001-local-first-development.md
  04_ADR/ADR-0002-github-source-of-truth.md
  04_ADR/ADR-0003-obsidian-knowledge-interface.md
  04_ADR/ADR-0004-hermes-deferred-phase-2.md
  11_Templates/PROJECT_TEMPLATE.md
  11_Templates/AGENT_TASK_TEMPLATE.md
  11_Templates/SOP_TEMPLATE.md
  11_Templates/SESSION_HANDOFF_TEMPLATE.md
  11_Templates/RELEASE_TEMPLATE.md
)

echo "Validating structure under: $ROOT"
echo

for d in "${required_folders[@]}"; do
  check_dir "$d"
done

echo

for f in "${required_files[@]}"; do
  check_file "$f"
done

echo
if [[ "$failed" -eq 0 ]]; then
  echo "RESULT: PASS (all checks ok)"
  exit 0
else
  echo "RESULT: FAIL ($failed check(s) failed)"
  exit 1
fi
