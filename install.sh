#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"

echo "Installing Claude Swarm Config..."
echo ""

# Create directories
mkdir -p "$AGENTS_DIR"

# Copy agents
echo "Copying agents to $AGENTS_DIR..."
cp "$SCRIPT_DIR/agents/"*.md "$AGENTS_DIR/"
echo "  Copied $(ls "$SCRIPT_DIR/agents/"*.md | wc -l | tr -d ' ') agents"

# Copy coordinator prompt
echo "Copying coordinator prompt..."
cp "$SCRIPT_DIR/coordinator-prompt.md" "$CLAUDE_DIR/coordinator-prompt.md"

# Copy config (merge if exists)
if [ -f "$CLAUDE_DIR/config.json" ]; then
    echo ""
    echo "WARNING: $CLAUDE_DIR/config.json already exists."
    echo "  Current config preserved. Recommended settings:"
    echo '  {"teammateMode": "tmux", "teammateDefaultModel": "claude-sonnet-4-6"}'
    echo "  Review and merge manually if needed."
else
    cp "$SCRIPT_DIR/config.json" "$CLAUDE_DIR/config.json"
    echo "Copied config.json"
fi

# Copy hooks
echo "Copying enforcement hooks..."
mkdir -p "$CLAUDE_DIR/hooks"
cp "$SCRIPT_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh
echo "  Copied $(ls "$SCRIPT_DIR/hooks/"*.sh | wc -l | tr -d ' ') hooks"
echo "  Hooks:"
echo "    enforce-tdd.sh              — TDD phase enforcement"
echo "    enforce-test-before-fix.sh  — test-before-fix in Phase 5"
echo "    enforce-phase-gate.sh       — approval gate enforcement"
echo "    enforce-no-direct-impl.sh   — coordinator delegation + config protection"
echo "    enforce-research-first.sh   — research-before-implementation"
echo "    enforce-regression.sh       — full regression reminder in Phase 5"
echo "    enforce-safe-commands.sh    — blocks dangerous shell commands"
echo "    update-task-state.sh        — agent invocation tracking"

# Install settings.json (project-level — copy to current project or user-level)
echo ""
echo "Hook settings (settings.json):"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    echo "  WARNING: $CLAUDE_DIR/settings.json already exists."
    echo "  Hooks configuration saved to: $SCRIPT_DIR/settings.json"
    echo "  Merge manually into your existing settings.json."
else
    cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    echo "  Copied settings.json to $CLAUDE_DIR/settings.json"
fi

# Detect shell config file
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

# Add aliases
ALIASES='# Claude Code Swarm aliases
alias swarm='"'"'claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode dontAsk'"'"'
alias swarm-plan='"'"'claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode plan'"'"'
alias swarm-auto='"'"'claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode auto'"'"'
alias swarm-print='"'"'claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode auto -p'"'"''

if [ -n "$SHELL_RC" ]; then
    if grep -q "Claude Code Swarm aliases" "$SHELL_RC" 2>/dev/null; then
        echo ""
        echo "Shell aliases already present in $SHELL_RC"
    else
        echo "" >> "$SHELL_RC"
        echo "$ALIASES" >> "$SHELL_RC"
        echo ""
        echo "Added swarm aliases to $SHELL_RC"
    fi
else
    echo ""
    echo "Could not detect shell config. Add these aliases manually:"
    echo ""
    echo "$ALIASES"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Task tracking:"
echo "  Hooks use .claude/project-state/current-task.txt to identify the active task."
echo "  Write the task ID (e.g., TASK-001) to this file to set the current task pointer."
echo "  If current-task.txt is absent, hooks fall back to finding a single active task."
echo ""
echo "To enable hooks in a project, copy hooks into the project:"
echo "  cd ~/your-project"
echo "  mkdir -p .claude/hooks"
echo "  cp ~/.claude/hooks/*.sh .claude/hooks/"
echo "  cp ~/.claude/settings.json .claude/settings.json"
echo ""
echo "Usage:"
echo "  source $SHELL_RC    # reload shell (or open new terminal)"
echo "  cd ~/your-project"
echo "  swarm               # start a swarm session"
echo ""
echo "Aliases:"
echo "  swarm        - fully autonomous"
echo "  swarm-plan   - agents must present plans"
echo "  swarm-auto   - classifier-based permissions"
echo "  swarm-print  - headless/pipe mode"
