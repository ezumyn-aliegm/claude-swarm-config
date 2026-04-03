#!/usr/bin/env bash
# Hook: PreToolUse on Write|Edit
# Enforces "never fix without a test" — during Phase 5 validation,
# blocks implementation edits if no test file exists in the changeset.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Only enforce on Write and Edit
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# Skip test files — they're always allowed
if echo "$FILE_PATH" | grep -qiE '(\.test\.|\.spec\.|__tests__|test_|_test\.|\btests/)'; then
    exit 0
fi

# Skip non-code files
if echo "$FILE_PATH" | grep -qiE '\.(md|json|yaml|yml|toml|txt|css|scss|svg|png|jpg|ico|env)$'; then
    exit 0
fi

# Skip project state files
if echo "$FILE_PATH" | grep -qiE '\.claude/project-state/'; then
    exit 0
fi

# Only enforce during Phase 5 (validation)
# Read current task pointer
CURRENT_TASK_FILE="$CWD/.claude/project-state/current-task.txt"
if [[ -f "$CURRENT_TASK_FILE" ]]; then
    TASK_ID=$(cat "$CURRENT_TASK_FILE" | tr -d '[:space:]')
    ACTIVE_TASK="$CWD/.claude/project-state/tasks/active/${TASK_ID}.md"
    if [[ ! -f "$ACTIVE_TASK" ]]; then
        ACTIVE_TASK=""
    fi
else
    # Fallback: single active task
    ACTIVE_TASK=$(find "$CWD/.claude/project-state/tasks/active" -name "TASK-*.md" 2>/dev/null | head -1)
fi

if [[ -z "$ACTIVE_TASK" ]]; then
    exit 0
fi

CURRENT_PHASE=$(grep '\*\*Phase:\*\*' "$ACTIVE_TASK" | sed 's/.*\*\*Phase:\*\* //' | sed 's/ .*//' 2>/dev/null || echo "")

if [[ "$CURRENT_PHASE" != "5" ]]; then
    exit 0
fi

# During Phase 5, check if ANY file in the diff is a test file
ALL_CHANGED=$(git -C "$CWD" diff --name-only HEAD 2>/dev/null; git -C "$CWD" diff --cached --name-only 2>/dev/null)
if echo "$ALL_CHANGED" | grep -qiE '(\.test\.|\.spec\.|__tests__|test_|_test\.|\btests/)'; then
    exit 0  # A test file exists in the changeset
fi

echo "TDD VIOLATION (Phase 5): Bug fixes require a failing test FIRST. Write a test that reproduces the bug, then fix the implementation." >&2
exit 2
