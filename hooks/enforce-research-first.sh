#!/usr/bin/env bash
# Hook: PreToolUse on Agent
# Enforces "always research first" — blocks spawning implementer/frontend-dev
# agents if no research brief artifact exists for the active task.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Only enforce on Agent tool
if [[ "$TOOL_NAME" != "Agent" ]]; then
    exit 0
fi

# Check which agent type is being spawned
AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // ""')
AGENT_DESC=$(echo "$INPUT" | jq -r '.tool_input.description // ""' | tr '[:upper:]' '[:lower:]')

# Only enforce for implementation agents
IS_IMPL=false
if [[ "$AGENT_TYPE" == "implementer" || "$AGENT_TYPE" == "frontend-dev" ]]; then
    IS_IMPL=true
fi
if echo "$AGENT_DESC" | grep -qiE '(implement|build|code|write code|create component)'; then
    IS_IMPL=true
fi

if [[ "$IS_IMPL" != "true" ]]; then
    exit 0
fi

# Check for active task
ACTIVE_TASK=$(find "$CWD/.claude/project-state/tasks/active" -name "TASK-*.md" 2>/dev/null | head -1)

if [[ -z "$ACTIVE_TASK" ]]; then
    exit 0  # No task tracking, can't enforce
fi

# Extract task number
TASK_NUM=$(basename "$ACTIVE_TASK" .md)

# Check if research brief exists
RESEARCH_BRIEF=$(find "$CWD/.claude/project-state/artifacts" -name "${TASK_NUM}-research-brief-*" 2>/dev/null | head -1)

# Check task type — config changes and S-size features skip research
TASK_TYPE=$(grep -oP '(?<=\*\*Type:\*\* )\S+' "$ACTIVE_TASK" 2>/dev/null || echo "")
TASK_SIZE=$(grep -oP '(?<=\*\*Size:\*\* )\S+' "$ACTIVE_TASK" 2>/dev/null || echo "")

if [[ "$TASK_TYPE" == "Config" ]]; then
    exit 0  # Config changes skip research
fi

if [[ -z "$RESEARCH_BRIEF" && "$TASK_SIZE" != "S" ]]; then
    echo "RESEARCH VIOLATION: No research brief found for $TASK_NUM. Complete Phase 1 (research) before spawning implementation agents. Use the researcher agent first." >&2
    exit 2
fi

exit 0
