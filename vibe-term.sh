#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  🚀 Vibe Terminal - 바이브 코딩용 8-pane 터미널 매니저
#
#  Usage: ./vibe-term.sh [panes] [session-name]
#    panes        Number of panes (default: 8)
#    session-name Session name (default: vibe)
#
#  Keybindings (prefix: Ctrl+a):
#    1-8    → Jump to pane
#    x      → Close current pane
#    n      → New pane
#    f      → Fullscreen toggle
#    Arrows → Navigate panes
#    q      → Quit all
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${SCRIPT_DIR}/vibe-term.conf"
PANES="${1:-8}"
SESSION="${2:-vibe}"

# ── Preflight ──────────────────────────────────────────────
if ! command -v tmux &>/dev/null; then
    echo "❌ tmux not found. Install with: brew install tmux"
    exit 1
fi

if [[ ! -f "$CONF" ]]; then
    echo "❌ Config not found: $CONF"
    exit 1
fi

if [[ "$PANES" -lt 1 || "$PANES" -gt 16 ]]; then
    echo "❌ Pane count must be 1-16 (got: $PANES)"
    exit 1
fi

# ── Kill existing session if present ───────────────────────
tmux kill-session -t "$SESSION" 2>/dev/null || true

# ── Create session with custom config ─────────────────────
tmux new-session -d -s "$SESSION" -x "$(tput cols)" -y "$(tput lines)"

# Source our config
tmux source-file "$CONF"

# ── Create panes (first pane already exists) ───────────────
for ((i = 2; i <= PANES; i++)); do
    tmux split-window -t "$SESSION"
    tmux select-layout -t "$SESSION" tiled
done

# ── Apply final tiled layout ──────────────────────────────
tmux select-layout -t "$SESSION" tiled

# ── Set pane titles ───────────────────────────────────────
for ((i = 1; i <= PANES; i++)); do
    tmux select-pane -t "$SESSION:.${i}" -T "pane-${i}"
done

# ── Focus first pane ─────────────────────────────────────
tmux select-pane -t "$SESSION:.1"

# ── Welcome message in each pane ─────────────────────────
for ((i = 1; i <= PANES; i++)); do
    tmux send-keys -t "$SESSION:.${i}" "echo '🎨 Vibe Terminal pane ${i}/${PANES} — prefix: Ctrl+a'" Enter
done

# ── Attach ────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     🚀 Vibe Terminal Launching...    ║"
echo "  ║                                      ║"
echo "  ║  Panes: ${PANES}                           ║"
echo "  ║  Prefix: Ctrl+a                      ║"
echo "  ║                                      ║"
echo "  ║  1-8: jump  x: close  n: new         ║"
echo "  ║  f: zoom    q: quit   ←↑↓→: move     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

exec tmux attach-session -t "$SESSION"
