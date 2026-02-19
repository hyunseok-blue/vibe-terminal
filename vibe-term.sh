#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  🚀 Vibe Terminal - 바이브 코딩용 9-pane 터미널 매니저
#
#  Usage: ./vibe-term.sh [panes] [session-name]
#    panes        Number of panes (default: 9)
#    session-name Session name (default: vibe)
#
#  Keybindings (prefix: Ctrl+a):
#    1-9    → Jump to pane
#    x      → Close current pane
#    n      → New pane
#    f      → Fullscreen toggle
#    e      → Equalize pane sizes
#    Arrows → Navigate panes
#    HJKL   → Resize panes (repeatable)
#    q      → Quit all
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${SCRIPT_DIR}/vibe-term.conf"
PANES="${1:-9}"
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
if [[ "$PANES" -eq 9 ]]; then
    # Manual 3x3 equal grid using stable pane IDs (avoids pane-base-index issues)
    # Step 1: Create 3 columns (left 33% | middle 33% | right 33%)
    COL1=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
    tmux split-window -h -p 67 -t "$COL1"
    COL2=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
    tmux split-window -h -p 50 -t "$COL2"
    COL3=$(tmux display-message -t "$SESSION" -p '#{pane_id}')

    # Step 2: Split each column into 3 rows (33% | 33% | 33%)
    for col in "$COL1" "$COL2" "$COL3"; do
        tmux split-window -v -p 67 -t "$col"
        bottom=$(tmux display-message -t "$SESSION" -p '#{pane_id}')
        tmux split-window -v -p 50 -t "$bottom"
    done

    # Equalize all panes to uniform 3x3 grid
    tmux select-layout -t "$SESSION" tiled
else
    # Non-9 pane counts: use tiled layout
    for ((i = 2; i <= PANES; i++)); do
        tmux split-window -t "$SESSION"
        tmux select-layout -t "$SESSION" tiled
    done
    tmux select-layout -t "$SESSION" tiled
fi

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

# ── Auto-launch system monitor in last pane (9+ panes) ──
if [[ "$PANES" -ge 9 ]]; then
    MONITOR_PANE="$PANES"
    MONITOR_CMD=""

    if command -v btop &>/dev/null; then
        MONITOR_CMD="btop"
    elif command -v htop &>/dev/null; then
        MONITOR_CMD="htop"
    elif [[ -x "${SCRIPT_DIR}/vibe-monitor.sh" ]]; then
        MONITOR_CMD="${SCRIPT_DIR}/vibe-monitor.sh"
    elif [[ "$(uname)" == "Darwin" ]]; then
        MONITOR_CMD="top -o cpu"
    else
        MONITOR_CMD="top"
    fi

    tmux send-keys -t "$SESSION:.${MONITOR_PANE}" "$MONITOR_CMD" Enter
fi

# ── Attach ────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     🚀 Vibe Terminal Launching...    ║"
echo "  ║                                      ║"
echo "  ║  Panes: ${PANES}                           ║"
echo "  ║  Prefix: Ctrl+a                      ║"
echo "  ║                                      ║"
echo "  ║  1-9: jump  x: close  n: new         ║"
echo "  ║  f: zoom    e: equal  q: quit        ║"
echo "  ║  ←↑↓→: move  HJKL: resize            ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

exec tmux attach-session -t "$SESSION"
