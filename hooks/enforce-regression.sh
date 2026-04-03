#!/usr/bin/env bash
# Hook: PostToolUse on Bash
# Enforces full regression at Phase 5 exit.
# After test commands complete during Phase 5, checks if a full suite run
# has been done (not just a single test file).

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""' | head -20)

# Only check Bash commands
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# Only check test-related commands
if ! echo "$COMMAND" | grep -qiE '(npm test|npx jest|yarn test|pytest|go test|cargo test|vitest|mocha|bun test)'; then
    exit 0
fi

# Check if we're in Phase 5
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

# Check if this was a targeted test run (single file) vs full suite
if echo "$COMMAND" | grep -qiE '(-- [^ ]+\.(test|spec)|--testPathPattern|--grep|-k |::|specific)'; then
    # This was a targeted test, not a full regression
    echo "REGRESSION REMINDER: This was a targeted test run during Phase 5. Remember: a full regression suite must pass before Phase 5 exit." >&2
    exit 0  # Warning only, don't block
fi

exit 0
