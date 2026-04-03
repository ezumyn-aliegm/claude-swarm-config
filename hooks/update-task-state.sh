#!/usr/bin/env bash
# Hook: PostToolUse on Agent
# Automatically updates the task file phase/status after agent completions.
# Tracks which agents have been spawned per phase for DA coverage verification.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Only trigger on Agent tool completion
if [[ "$TOOL_NAME" != "Agent" ]]; then
    exit 0
fi

AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // ""')
STATE_DIR="$CWD/.claude/project-state"

# Skip if no project state directory
if [[ ! -d "$STATE_DIR" ]]; then
    exit 0
fi

# Log agent invocation for DA coverage tracking
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
    ACTIVE_TASK=$(find "$STATE_DIR/tasks/active" -name "TASK-*.md" 2>/dev/null | head -1)
fi

if [[ -z "$ACTIVE_TASK" ]]; then
    exit 0
fi

TASK_NUM=$(basename "$ACTIVE_TASK" .md)
CURRENT_PHASE=$(grep '\*\*Phase:\*\*' "$ACTIVE_TASK" | sed 's/.*\*\*Phase:\*\* //' | sed 's/ .*//' 2>/dev/null || echo "0")

# Append to agent invocation log
AGENT_LOG="$STATE_DIR/artifacts/${TASK_NUM}-agent-log.txt"

# Use mkdir-based locking for macOS compatibility (flock not available)
LOCKDIR="$STATE_DIR/.task-lock"
if mkdir "$LOCKDIR" 2>/dev/null; then
    trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) phase=$CURRENT_PHASE agent=$AGENT_TYPE" >> "$AGENT_LOG"

    # Update timestamp on task file
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/\*\*Updated:\*\* .*/\*\*Updated:\*\* $(date +%Y-%m-%d)/" "$ACTIVE_TASK" 2>/dev/null || true
    else
        sed -i "s/\*\*Updated:\*\* .*/\*\*Updated:\*\* $(date +%Y-%m-%d)/" "$ACTIVE_TASK" 2>/dev/null || true
    fi
fi

exit 0
