# Claude Code Swarm Config

A production-ready multi-agent coordinator workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Turn your CLI into a full development team with specialized agents, TDD enforcement, structured devil's advocacy, and project state management.

## What This Is

A set of agent definitions and a coordinator system prompt that makes Claude Code orchestrate work across 11 specialized agents:

| Agent | Role | Model |
|-------|------|-------|
| **researcher** | Investigate codebases, docs, patterns | sonnet |
| **architect** | Design plans, review implementations | opus |
| **ux-designer** | User flows, interaction design, usability | opus |
| **ui-designer** | Visual design, spacing, color, typography | opus |
| **frontend-dev** | React/TypeScript/CSS implementation | opus |
| **implementer** | Backend/general code implementation | opus |
| **tester** | Write and run tests (TDD) | sonnet |
| **reviewer** | Code review, security, test quality | sonnet |
| **qa-user** | Non-technical end user testing | sonnet |
| **devils-advocate** | Challenge everything, every phase | opus |
| **browser-qa-tester** | Browser automation QA | sonnet |

## Workflow

The coordinator runs a structured, phase-gated workflow:

```
Phase 0: Triage ─── classify task (type x size), set up tracking
    │
Phase 1: Understand ─── researcher + devil's advocate
    │
Phase 2: Design ─── architect + UX/UI + devil's advocate
    │                    ▼
    │              USER APPROVAL
    │                    ▼
Phase 3: Red ─── tester writes failing tests + test design review
    │
Phase 3.5: Green ─── implementers write minimum code to pass
    │                    ▼
    │              USER CHECKPOINT (L: blocking, M: advisory, S: skip)
    │                    ▼
Phase 4: Refactor ─── reviewer + architect approve
    │
Phase 5: Validate ─── tester + qa-user + browser QA + devil's advocate
    │
Phase 6: Deliver ─── delivery summary + user ships
    │
Phase 7: Retro ─── what to improve next time
```

### Key Features

- **TDD mandatory** — Red, Green, Refactor. Tests before code, always.
- **Devil's advocate in every phase** — structured rubric with category rotation, blocking vs advisory, one round max, all challenges tracked.
- **Task triage matrix** — classifies work by type (Feature/Bug/Refactor/Research/Config) and size (S/M/L). Each combo maps to a subset of phases. A config change doesn't go through 7 phases.
- **Versioned artifacts** — every phase transition has a defined input/output contract. No stale context.
- **Tiered regression** — affected-path per fix, full suite at phase exit. Not a 15-minute regression after every one-line fix.
- **Project state management** — auto-detects GitHub Projects/Issues or falls back to local file-based tracking in `.claude/project-state/`.
- **Severity levels** — P0/P1/P2/P3 with clear definitions. P2+ deferred to backlog, not fixed in-cycle.
- **Backlog grooming** — every 10th task, auto-archive stale items.
- **Retro with active experiments** — top improvement becomes an experiment for the next task.

## Installation

### Quick Install (copy to your Claude config)

```bash
# Clone the repo
git clone https://github.com/aliegm/claude-swarm-config.git

# Copy agents to your Claude config
cp claude-swarm-config/agents/*.md ~/.claude/agents/

# Copy the coordinator prompt
cp claude-swarm-config/coordinator-prompt.md ~/.claude/coordinator-prompt.md

# Copy the config
cp claude-swarm-config/config.json ~/.claude/config.json
```

### Add Shell Aliases

Add these to your `~/.zshrc` or `~/.bashrc`:

```bash
# Claude Code Swarm aliases
alias swarm='claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode dontAsk'
alias swarm-plan='claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode plan'
alias swarm-auto='claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode auto'
alias swarm-print='claude --append-system-prompt-file ~/.claude/coordinator-prompt.md --permission-mode auto -p'
```

Then reload:

```bash
source ~/.zshrc
```

### Install Script

Or use the install script:

```bash
./install.sh
```

## Usage

### Start a swarm session

```bash
cd ~/your-project
swarm
```

Then just describe what you want:

```
> Add a dark mode toggle to the settings page
```

The coordinator will automatically:
1. Triage (Feature/M)
2. Research the current theming setup
3. Have the architect + UX + UI design a plan
4. Wait for your approval
5. Write failing tests
6. Implement to pass tests
7. Refactor with architect review
8. Validate with QA + browser tests
9. Present delivery summary
10. Ask if you want to ship

### Aliases

| Alias | Permission Mode | Use Case |
|-------|----------------|----------|
| `swarm` | dontAsk | Fully autonomous — fastest |
| `swarm-plan` | plan | Agents must present plans before acting |
| `swarm-auto` | auto | Classifier-based auto permissions |
| `swarm-print "task"` | auto + headless | Pipe-friendly, CI/CD, scripts |

### Direct agent usage

You can also reference agents directly in any Claude Code session (no swarm alias needed):

```
> Use the devils-advocate to review this PR
> Have the researcher find all auth patterns in this repo
> Ask the ux-designer to audit the checkout flow
```

## Project State

The coordinator tracks work automatically. It detects your setup:

1. **GitHub Project + Issues** — syncs via `gh` CLI
2. **GitHub Issues only** — creates/updates issues, links PRs
3. **Local fallback** — maintains `.claude/project-state/` in your repo:

```
.claude/project-state/
├── PROJECT.md          # Overview, active tasks, recent completions
├── BACKLOG.md          # Deferred work, groomed every 10 tasks
├── tasks/
│   ├── active/         # In-progress task files
│   ├── done/           # Completed task files
│   └── counter.txt     # Next task number
├── artifacts/          # Versioned phase artifacts
├── da-log.md           # Devil's advocate log across all tasks
└── retros/             # Retro notes per task
```

## Enforcement Hooks

The workflow rules aren't just guidelines — they're enforced by Claude Code hooks that block violations in real-time.

### What Gets Enforced

| Hook | Event | What It Does |
|------|-------|-------------|
| `enforce-tdd.sh` | PreToolUse (Write/Edit) | Blocks writing implementation code during Phase 3 (Red). Only test files allowed. Blocks all code during Phases 0-2. |
| `enforce-test-before-fix.sh` | PreToolUse (Write/Edit) | During Phase 5, blocks implementation edits unless a test file was the most recent change. Forces "failing test first, then fix." |
| `enforce-phase-gate.sh` | PreToolUse (Write/Edit) | Blocks code changes when task status is `awaiting-approval`. Enforces user approval gates. |
| `enforce-no-direct-impl.sh` | PreToolUse (Write/Edit) | Blocks the coordinator from writing code directly. Only subagents (with `agent_id`) can write code files. |
| `enforce-research-first.sh` | PreToolUse (Agent) | Blocks spawning implementer/frontend-dev agents if no research brief artifact exists for the active task. |
| `enforce-regression.sh` | PostToolUse (Bash) | Warns when running targeted tests during Phase 5 — reminds that full regression must pass before phase exit. |
| `update-task-state.sh` | PostToolUse (Agent) | Logs agent invocations per phase for DA coverage tracking. Updates task file timestamps. |
| DA coverage check | Stop (prompt) | LLM-based check that the devil's advocate was invoked in the current phase before concluding. |
| State update check | Stop (prompt) | LLM-based check that the task file was updated after phase transitions. |
| Agent output review | SubagentStop (prompt) | LLM-based review of agent work: test quality (behavior vs implementation), minimum code rule, DA format compliance. |
| Project state loader | SessionStart | Loads and displays active project state at session start. |

### How Hooks Work

Hooks intercept Claude Code tool calls and can **block** them (exit code 2) or **warn** (exit code 0 with stderr message):

```
Claude wants to edit src/App.tsx
  → enforce-tdd.sh checks: Is the task in Phase 3 (Red)?
  → YES → exit 2: "TDD VIOLATION: Only test files allowed in Phase 3"
  → Claude is blocked, must write tests first
```

```
Claude is about to stop responding
  → DA coverage prompt checks: Was devils-advocate spawned this phase?
  → NO → "DA VIOLATION: Spawn the devils-advocate before concluding"
  → Claude continues, spawns DA
```

### Installing Hooks in a Project

After running `./install.sh`, enable hooks per-project:

```bash
cd ~/your-project
mkdir -p .claude/hooks
cp ~/.claude/hooks/*.sh .claude/hooks/
cp ~/.claude/settings.json .claude/settings.json
```

Or use project-level settings only (`.claude/settings.json` in your repo).

### Disabling Individual Hooks

Remove or comment out the specific hook entry in your `.claude/settings.json`. Each hook is independent.

## Customization

### Swap models

Edit the `model:` field in any agent's frontmatter:

```yaml
---
model: sonnet    # or opus, haiku
---
```

### Add/remove agents

Drop a `.md` file in `~/.claude/agents/` with this frontmatter:

```yaml
---
name: my-agent
description: "When to use this agent"
model: opus
color: green
---

Your agent prompt here.
```

### Modify the workflow

Edit `~/.claude/coordinator-prompt.md`. The triage matrix, phase definitions, and rules are all in one file.

## File Structure

```
claude-swarm-config/
├── README.md                  # This file
├── CHANGELOG.md               # Version history
├── install.sh                 # Installation script
├── coordinator-prompt.md      # The coordinator system prompt
├── config.json                # Claude Code config (teammate preferences)
├── settings.json              # Hook configuration for enforcement
├── agents/                    # Agent definitions
│   ├── architect.md
│   ├── browser-qa-tester.md
│   ├── devils-advocate.md
│   ├── frontend-dev.md
│   ├── implementer.md
│   ├── qa-user.md
│   ├── researcher.md
│   ├── reviewer.md
│   ├── tester.md
│   ├── ui-designer.md
│   └── ux-designer.md
├── hooks/                     # Enforcement hook scripts
│   ├── enforce-tdd.sh         # Block impl code before tests
│   ├── enforce-test-before-fix.sh  # Require test before bug fix
│   ├── enforce-phase-gate.sh  # Block code during approval gates
│   ├── enforce-no-direct-impl.sh   # Coordinator can't write code
│   ├── enforce-research-first.sh   # Research before implementation
│   ├── enforce-regression.sh  # Regression reminders in Phase 5
│   ├── enforce-da-required.sh # DA coverage documentation
│   └── update-task-state.sh   # Track agent invocations
└── examples/                  # Example project state files
    ├── PROJECT.md
    ├── BACKLOG.md
    └── TASK-001.md
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `tmux` for multi-pane agent display (`brew install tmux`)
- `gh` CLI for GitHub integration (optional, `brew install gh`)

## How It Was Built

This workflow was designed iteratively with two rounds of expert panel review:

**Round 1** (5 panelists): Staff SWE, Engineering Manager, QA Director, DevOps Engineer, Agile Coach. Identified: missing triage, no error handling, DA noise risk, underspecified artifacts, Phase 5 infinite loops.

**Round 2** (7 panelists): Principal Engineer, VP Engineering, Senior SDET, Incident Commander, Product Manager, Cognitive Scientist, Technical Program Manager. Identified: undefined triage matrix, no artifact versioning, gate fatigue, no time-boxing, late test quality review.

All findings were applied. The panel unanimously agreed to NOT change: TDD phase structure, DA one-round cap, three user gate points, and the agent role table.

## License

MIT
