# Claude Agents

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
git clone https://github.com/lajlev/claude-agents.git
cd claude-agents

# Example on how to make claude-agents available globally
ln -sf "$(pwd)/claude-agents.sh" /opt/homebrew/bin/claude-agents
```

## Usage

```bash
# Run in the current directory
claude-agents

# Run in a specific project directory
claude-agents ~/my-project
```

## Tmux controls

| Action | Keys |
|---|---|
| Switch panes | `Ctrl+B` then arrow keys |
| Scroll a pane | `Ctrl+B` then `[` |
| Detach session | `Ctrl+B` then `d` |
| Reattach | `tmux attach -t claude-agents` |
| Kill session | `tmux kill-session -t claude-agents` |

## License

MIT
