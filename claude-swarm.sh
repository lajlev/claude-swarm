#!/usr/bin/env bash
# ============================================================================
# claude-swarm.sh — Multi-agent Claude Code orchestrator in tmux
#
# Layout:  4 panes in one tmux window
#   ┌──────────────┬──────────────┐
#   │  PM (top-L)  │ Agent1(top-R)│
#   ├──────────────┼──────────────┤
#   │ Agent2(bot-L)│ Agent3(bot-R)│
#   └──────────────┴──────────────┘
#
# The Product Manager runs in interactive mode so YOU can see its
# conversation and intervene when it escalates critical questions.
# The 3 Code Agents run in interactive mode in their own panes.
#
# Usage:
#   chmod +x claude-swarm.sh
#   ./claude-swarm.sh [project-dir]
#
# Requirements: tmux, claude (Claude Code CLI)
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SESSION_NAME="claude-swarm"
PROJECT_DIR="${1:-.}"                         # default: current directory
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"     # resolve to absolute path

# Colors for pane titles (using tmux pane-border-format)
PM_COLOR="#[fg=yellow,bold]"
AGENT_COLOR="#[fg=cyan]"

# CLAUDE.md instructions injected into each role
PM_SYSTEM=$(cat <<'PROMPT'
You are the PRODUCT MANAGER in a multi-agent Claude Code swarm.

## Your role
- You coordinate 3 Code Agents working in parallel in adjacent tmux panes.
- You break down the user's high-level goal into concrete tasks.
- You assign tasks by telling the human operator which agent should do what.
- You review work, unblock agents, answer their technical questions, and keep the project on track.

## Communication rules
- ONLY escalate to the human operator when:
  • A decision has significant business/product impact
  • There is ambiguity in requirements that you cannot resolve
  • A task would delete data, cost money, or deploy to production
  • Two agents have a conflicting approach and you need a tiebreaker
- For everything else (technical questions, code review, architecture decisions, debugging), handle it yourself.
- When you DO escalate, prefix your message with "⚠️ ESCALATION:" so the operator can spot it quickly.

## Workflow
1. Ask the human for the high-level goal (only once at the start).
2. Break it into tasks and present a plan.
3. Tell the operator which task to paste into which agent pane.
4. Monitor progress — the operator will copy agent output to you if needed.
5. Iterate until done.
PROMPT
)

AGENT_SYSTEM=$(cat <<'PROMPT'
You are a CODE AGENT in a multi-agent Claude Code swarm.

## Your role
- You receive specific, scoped coding tasks from the Product Manager.
- You execute them thoroughly: write code, run tests, fix bugs.
- You report back with a SHORT summary of what you did and any blockers.

## Rules
- Stay focused on your assigned task. Don't wander into other agents' work.
- If you are blocked or confused, clearly state what you need so the PM can unblock you.
- Prefer small, testable commits.
- If a task is unclear, ask ONE clarifying question, then proceed with your best judgment.
PROMPT
)

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
if ! command -v tmux &>/dev/null; then
    echo "❌ tmux is not installed. Install it first (e.g. brew install tmux / apt install tmux)"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo "❌ Claude Code CLI ('claude') not found in PATH."
    echo "   Install: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Kill existing session if any
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Write temporary CLAUDE.md files for each role
# ---------------------------------------------------------------------------
SWARM_DIR="$PROJECT_DIR/.claude-swarm"
mkdir -p "$SWARM_DIR"

cat > "$SWARM_DIR/pm-instructions.md" << 'EOF'
# Product Manager Instructions

You are the Product Manager in a multi-agent swarm. See your system prompt for full details.
Key reminders:
- Only escalate critical decisions with "⚠️ ESCALATION:" prefix
- Break work into tasks for 3 code agents
- Keep the project moving forward
EOF

cat > "$SWARM_DIR/agent-instructions.md" << 'EOF'
# Code Agent Instructions

You are a Code Agent in a multi-agent swarm. See your system prompt for full details.
Key reminders:
- Stay focused on your assigned task
- Report blockers clearly
- Prefer small, testable changes
EOF

# ---------------------------------------------------------------------------
# Build the tmux session
# ---------------------------------------------------------------------------
# Create session with first pane (PM)
tmux new-session -d -s "$SESSION_NAME" -x 220 -y 55 -c "$PROJECT_DIR"

# Enable pane titles
tmux set-option -t "$SESSION_NAME" pane-border-status top
tmux set-option -t "$SESSION_NAME" pane-border-format \
    "#{?pane_active,#[reverse],} #{pane_title} #[default]"

# Split into 4 panes (2x2 grid)
#   Pane 0: top-left  (PM)
#   Pane 1: top-right (Agent 1)
#   Pane 2: bottom-left (Agent 2)
#   Pane 3: bottom-right (Agent 3)
tmux split-window -h -t "$SESSION_NAME" -c "$PROJECT_DIR"
tmux split-window -v -t "$SESSION_NAME:0.0" -c "$PROJECT_DIR"
tmux split-window -v -t "$SESSION_NAME:0.1" -c "$PROJECT_DIR"

# Name the panes
tmux select-pane -t "$SESSION_NAME:0.0" -T "🎯 Product Manager"
tmux select-pane -t "$SESSION_NAME:0.1" -T "🔧 Code Agent 1"
tmux select-pane -t "$SESSION_NAME:0.2" -T "🔧 Code Agent 2"
tmux select-pane -t "$SESSION_NAME:0.3" -T "🔧 Code Agent 3"

# ---------------------------------------------------------------------------
# Launch Claude Code in each pane
# ---------------------------------------------------------------------------

# Product Manager (interactive — this is where you'll interact)
tmux send-keys -t "$SESSION_NAME:0.0" \
    "claude --system-prompt '${PM_SYSTEM//\'/\\'\\'}'" Enter

# Agent 1
tmux send-keys -t "$SESSION_NAME:0.1" \
    "claude --system-prompt '${AGENT_SYSTEM//\'/\\'\\'}'" Enter

# Agent 2
tmux send-keys -t "$SESSION_NAME:0.2" \
    "claude --system-prompt '${AGENT_SYSTEM//\'/\\'\\'}'" Enter

# Agent 3
tmux send-keys -t "$SESSION_NAME:0.3" \
    "claude --system-prompt '${AGENT_SYSTEM//\'/\\'\\'}'" Enter

# Focus on the PM pane
tmux select-pane -t "$SESSION_NAME:0.0"

# ---------------------------------------------------------------------------
# Attach
# ---------------------------------------------------------------------------
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           🐝  Claude Swarm is starting up!                  ║"
echo "║                                                             ║"
echo "║  Layout:                                                    ║"
echo "║  ┌─────────────────┬─────────────────┐                     ║"
echo "║  │ 🎯 Product Mgr  │ 🔧 Agent 1      │                     ║"
echo "║  ├─────────────────┼─────────────────┤                     ║"
echo "║  │ 🔧 Agent 2      │ 🔧 Agent 3      │                     ║"
echo "║  └─────────────────┴─────────────────┘                     ║"
echo "║                                                             ║"
echo "║  Tips:                                                      ║"
echo "║  • Talk to the PM in the top-left pane                     ║"
echo "║  • Switch panes: Ctrl+B then arrow keys                    ║"
echo "║  • Scroll pane:  Ctrl+B then [                             ║"
echo "║  • Detach:       Ctrl+B then d                             ║"
echo "║  • Reattach:     tmux attach -t claude-swarm               ║"
echo "║  • Kill all:     tmux kill-session -t claude-swarm         ║"
echo "║                                                             ║"
echo "║  The PM will only escalate critical decisions to you.       ║"
echo "║  Look for ⚠️  ESCALATION: messages.                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

tmux attach-session -t "$SESSION_NAME"
