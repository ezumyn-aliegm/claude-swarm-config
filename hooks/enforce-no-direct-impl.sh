#!/usr/bin/env bash
# Hook: PreToolUse on Write|Edit
# Enforces "coordinator never implements" — blocks the coordinator from writing
# code directly instead of delegating to agents.
# Also protects orchestration config files from ALL modifications during swarm sessions.
# Only active when running with the coordinator prompt (swarm aliases).

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')

# Only enforce on Write and Edit
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# Block ALL modifications to orchestration config files, even by agents
if echo "$FILE_PATH" | grep -qiE '(coordinator-prompt\.md|\.claude/settings\.json|\.claude/settings\.local\.json|\.claude/agents/)'; then
    echo "CONFIG PROTECTION: Orchestration configuration files cannot be modified during a swarm session." >&2
    exit 2
fi

# If this is a subagent (has agent_id), allow — agents ARE supposed to write code
if [[ -n "$AGENT_ID" ]]; then
    exit 0
fi

# Skip non-code files — coordinator CAN write docs, configs, project state
if echo "$FILE_PATH" | grep -qiE '\.(md|json|yaml|yml|toml|txt|csv|env)$'; then
    exit 0
fi
if echo "$FILE_PATH" | grep -qiE '\.claude/'; then
    exit 0
fi

# If we reach here, the coordinator (non-agent) is trying to write code
echo "COORDINATOR VIOLATION: The coordinator must NOT write implementation code directly. Delegate to the appropriate agent (implementer, frontend-dev, tester, etc.) using the Agent tool." >&2
exit 2
