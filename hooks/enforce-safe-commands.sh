#!/usr/bin/env bash
# Hook: PreToolUse on Bash
# Blocks dangerous commands that could destroy data or modify orchestration config.
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# Block destructive file operations
if echo "$COMMAND" | grep -qiE '(rm\s+-rf\s+[/~.]|rm\s+-rf\s+\*|rmdir\s+/)'; then
    echo "SAFETY BLOCK: Destructive file operation detected. This command could delete critical files." >&2
    exit 2
fi

# Block force pushes to main/master
if echo "$COMMAND" | grep -qiE 'git\s+push\s+.*--force.*\s+(main|master)|git\s+push\s+-f.*\s+(main|master)'; then
    echo "SAFETY BLOCK: Force push to main/master is blocked." >&2
    exit 2
fi

# Block modifications to orchestration config files via shell
if echo "$COMMAND" | grep -qiE '(>\s*|tee\s+|cp\s+.*)(\.claude/settings|\.claude/agents/|coordinator-prompt)'; then
    echo "SAFETY BLOCK: Modification of orchestration configuration files via shell is blocked during a swarm session." >&2
    exit 2
fi

# Block piping from internet directly to shell
if echo "$COMMAND" | grep -qiE '(curl|wget).*\|\s*(bash|sh|zsh)'; then
    echo "SAFETY BLOCK: Piping remote content to shell is blocked." >&2
    exit 2
fi

# Block file renames from exempt extensions to code extensions (anti-gaming)
if echo "$COMMAND" | grep -qiE '(mv|cp)\s+.*\.(md|txt|json)\s+.*\.(ts|tsx|js|jsx|py|rb|go|rs|java|swift|kt)'; then
    echo "SAFETY BLOCK: Renaming non-code files to code extensions is blocked. Write code files directly." >&2
    exit 2
fi

exit 0
