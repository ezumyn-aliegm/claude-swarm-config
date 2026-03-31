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
