#!/usr/bin/env bash
# Hook: PreToolUse on Write|Edit
# Enforces TDD — blocks writing implementation code if no failing tests exist yet.
# Reads hook input from stdin (JSON with tool_name, tool_input).

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Only enforce on Write and Edit tools
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# Skip if no file path
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Skip if the file being written IS a test file
if echo "$FILE_PATH" | grep -qiE '(\.test\.|\.spec\.|__tests__|test_|_test\.|\btests/)'; then
    exit 0
fi

# Skip if writing to non-code files (configs, docs, etc.)
if echo "$FILE_PATH" | grep -qiE '\.(md|json|yaml|yml|toml|txt|svg|png|jpg|ico|env)$'; then
    exit 0
fi

# Skip if writing to project state files
if echo "$FILE_PATH" | grep -qiE '\.claude/project-state/'; then
    exit 0
fi

# Skip hook/config files
if echo "$FILE_PATH" | grep -qiE '(\.claude/|settings\.json|hooks/)'; then
    exit 0
fi

# Check if any test files exist that reference related modules
# Look for test files in the project
SOURCE_BASENAME=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//')
TEST_FILES=$(find "$CWD" -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" \) 2>/dev/null | head -5)

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

if [[ -n "$ACTIVE_TASK" ]]; then
    CURRENT_PHASE=$(grep '\*\*Phase:\*\*' "$ACTIVE_TASK" | sed 's/.*\*\*Phase:\*\* //' | sed 's/ .*//' 2>/dev/null || echo "")
    CURRENT_STATUS=$(grep '\*\*Status:\*\*' "$ACTIVE_TASK" | sed 's/.*\*\*Status:\*\* //' | sed 's/ .*//' 2>/dev/null || echo "")

    # If we're in Phase 3.5 (green) or Phase 4 (refactor), implementation is allowed
    if [[ "$CURRENT_PHASE" == "3.5" || "$CURRENT_PHASE" == "4" || "$CURRENT_PHASE" == "5" ]]; then
        exit 0
    fi

    # If we're in Phase 3 (red), only test files should be written (already handled above)
    if [[ "$CURRENT_PHASE" == "3" && "$CURRENT_STATUS" == "red" ]]; then
        echo "TDD VIOLATION: Phase 3 (Red) — only test files should be written now. Write tests first, then implement in Phase 3.5." >&2
        exit 2
    fi

    # If we're in Phase 2 or earlier, no code should be written
    if [[ "$CURRENT_PHASE" == "0" || "$CURRENT_PHASE" == "1" || "$CURRENT_PHASE" == "2" ]]; then
        echo "TDD VIOLATION: Phase $CURRENT_PHASE — no implementation code allowed yet. Complete design and write tests first." >&2
        exit 2
    fi
fi

# If no task tracking, do a basic check: are there ANY test files for this source file?
if [[ -z "$ACTIVE_TASK" ]]; then
    MATCHING_TESTS=$(find "$CWD" -type f \( \
        -name "${SOURCE_BASENAME}.test.*" -o \
        -name "${SOURCE_BASENAME}.spec.*" -o \
        -name "${SOURCE_BASENAME}_test.*" -o \
        -name "test_${SOURCE_BASENAME}.*" \
    \) 2>/dev/null | head -1)

    # This is a soft warning, not a block, when there's no task tracking
    if [[ -z "$MATCHING_TESTS" && -n "$TEST_FILES" ]]; then
        echo "TDD WARNING: No test file found for '$SOURCE_BASENAME'. Consider writing tests first (Red → Green → Refactor)." >&2
        exit 0  # Warning only, don't block
    fi
fi

exit 0
