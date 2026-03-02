# Claude Swarm

Multi-agent Claude Code orchestrator using tmux. Spins up a **Product Manager** and **3 Code Agents** in a 2x2 grid, each running an independent Claude Code session with role-specific system prompts.

```
┌─────────────────┬─────────────────┐
│ 🎯 Product Mgr  │ 🔧 Agent 1      │
├─────────────────┼─────────────────┤
│ 🔧 Agent 2      │ 🔧 Agent 3      │
└─────────────────┴─────────────────┘
```

## How it works

- The **Product Manager** breaks down your high-level goal into tasks and coordinates the agents.
- The **Code Agents** receive scoped tasks, write code, run tests, and report back.
- The PM only escalates to you (the human operator) for critical decisions, prefixed with `⚠️ ESCALATION:`.
- You interact primarily in the PM pane and relay tasks to agent panes as directed.

## Requirements

- [tmux](https://github.com/tmux/tmux)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude`)

## Installation

```bash
# Clone the repo
git clone https://github.com/lajlev/claude-swarm.git
cd claude-swarm

# Make it available globally
ln -sf "$(pwd)/claude-swarm.sh" /opt/homebrew/bin/claude-swarm
```

## Usage

```bash
# Run in the current directory
claude-swarm

# Run in a specific project directory
claude-swarm ~/my-project
```

## Tmux controls

| Action | Keys |
|---|---|
| Switch panes | `Ctrl+B` then arrow keys |
| Scroll a pane | `Ctrl+B` then `[` |
| Detach session | `Ctrl+B` then `d` |
| Reattach | `tmux attach -t claude-swarm` |
| Kill session | `tmux kill-session -t claude-swarm` |

## License

MIT
