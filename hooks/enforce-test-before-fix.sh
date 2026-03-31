#!/usr/bin/env bash
# Hook: PreToolUse on Write|Edit
# Enforces "never fix without a test" — during Phase 5 validation,
# blocks implementation edits if the most recent change wasn't a test file.

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
ACTIVE_TASK=$(find "$CWD/.claude/project-state/tasks/active" -name "TASK-*.md" 2>/dev/null | head -1)

if [[ -z "$ACTIVE_TASK" ]]; then
    exit 0
fi

CURRENT_PHASE=$(grep -oP '(?<=\*\*Phase:\*\* )[\d.]+' "$ACTIVE_TASK" 2>/dev/null || echo "")

if [[ "$CURRENT_PHASE" != "5" ]]; then
    exit 0
fi

# During Phase 5, check if the last git change was a test file
LAST_CHANGED=$(git -C "$CWD" diff --name-only HEAD 2>/dev/null | tail -1)
LAST_STAGED=$(git -C "$CWD" diff --cached --name-only 2>/dev/null | tail -1)
LAST_FILE="${LAST_STAGED:-$LAST_CHANGED}"

if [[ -n "$LAST_FILE" ]]; then
    if echo "$LAST_FILE" | grep -qiE '(\.test\.|\.spec\.|__tests__|test_|_test\.|\btests/)'; then
        # Last change was a test file — implementation fix is allowed
        exit 0
    fi
fi

echo "TDD VIOLATION (Phase 5): Bug fixes require a failing test FIRST. Write a test that reproduces the bug, then fix the implementation." >&2
exit 2
