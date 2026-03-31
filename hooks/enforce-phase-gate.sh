#!/usr/bin/env bash
# Hook: PreToolUse on Write|Edit
# Blocks code changes when a user approval gate is pending.
# Gates: Phase 2 (plan approval) and Phase 3.5/L (prototype approval).

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Only enforce on Write and Edit
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# Skip non-code files (docs, configs, project state)
if echo "$FILE_PATH" | grep -qiE '\.(md|json|yaml|yml|toml|txt)$'; then
    exit 0
fi
if echo "$FILE_PATH" | grep -qiE '\.claude/project-state/'; then
    exit 0
fi

# Check for active task
ACTIVE_TASK=$(find "$CWD/.claude/project-state/tasks/active" -name "TASK-*.md" 2>/dev/null | head -1)

if [[ -z "$ACTIVE_TASK" ]]; then
    exit 0
fi

CURRENT_STATUS=$(grep -oP '(?<=\*\*Status:\*\* )\S+' "$ACTIVE_TASK" 2>/dev/null || echo "")

# Block if awaiting user approval
if [[ "$CURRENT_STATUS" == "awaiting-approval" ]]; then
    echo "GATE VIOLATION: Task is awaiting user approval. No code changes allowed until the user approves the plan. Present the plan and wait for approval." >&2
    exit 2
fi

exit 0
