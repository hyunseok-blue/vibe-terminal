<p align="center">
  <img src="https://img.shields.io/badge/tmux-powered-1BB91F?style=for-the-badge&logo=tmux&logoColor=white" alt="tmux powered">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="bash">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT License">
</p>

<h1 align="center">🎨 Vibe Terminal</h1>

<p align="center">
  <strong>Multi-pane terminal manager for vibe coding</strong><br>
  바이브 코딩을 위한 멀티 pane 터미널 매니저
</p>

<p align="center">
  One command. 9 panes. Pure vibe.
</p>

---

## What is this?

Vibe Terminal instantly launches a **pixel-perfect 3x3 equal grid** of terminal panes using tmux — perfect for vibe coding sessions where you need multiple terminals at a glance. Each pane is exactly 33% width and 33% height, and you can resize any pane by dragging its border with the mouse.

- Server, client, logs, tests, git, db, docs, scratch — all visible at once
- Built-in system monitor (CPU/memory) in the last pane
- Jump between panes with number keys
- Cyberpunk-inspired color theme (Tokyo Night palette)
- Pixel-perfect 3x3 equal grid (no uneven tiling)
- Mouse drag to resize any pane border
- Keyboard resize with Shift+Arrow keys
- Zero config needed, just run it

## Demo

```
┌──────────┬──────────┬──────────┐
│ 1:server │ 2:client │ 3:tests  │
│          │          │          │
├──────────┼──────────┼──────────┤
│ 4:logs   │ 5:git    │ 6:db     │
│          │          │          │
├──────────┼──────────┼──────────┤
│ 7:docs   │ 8:scratch│ 9:monitor│
│          │          │  (htop)  │
└──────────┴──────────┴──────────┘
      ⚡ VIBE ⚡  9 panes  23:00
```

## Requirements

- **tmux** 3.0+ (`brew install tmux`)
- **bash** 4.0+

## Installation

```bash
git clone https://github.com/hyunseok-blue/vibe-terminal.git ~/vibe-term
chmod +x ~/vibe-term/vibe-term.sh
```

### Add aliases (optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Vibe Terminal
alias vt='~/vibe-term/vibe-term.sh'       # 9 panes (default)
alias vt4='~/vibe-term/vibe-term.sh 4'    # 4 panes
alias vt6='~/vibe-term/vibe-term.sh 6'    # 6 panes
```

Then reload: `source ~/.zshrc`

## Usage

```bash
# Default: 9 panes (with system monitor)
vt

# Custom pane count (1-16)
vt4                                # 4 panes
vt6                                # 6 panes
~/vibe-term/vibe-term.sh 12       # 12 panes

# Custom session name
~/vibe-term/vibe-term.sh 8 myproject
```

## Keybindings

All keybindings use **`Ctrl+a`** as the prefix key.

| Key | Action |
|-----|--------|
| `Ctrl+a` then `1`-`9` | Jump to pane by number |
| `Ctrl+a` then `x` | Close current pane |
| `Ctrl+a` then `n` | Add new pane (auto re-tiles) |
| `Ctrl+a` then `f` | Toggle fullscreen (zoom) |
| `Ctrl+a` then `e` | Equalize all pane sizes |
| `Ctrl+a` then `←↑↓→` | Navigate to adjacent pane |
| `Ctrl+a` then `H/J/K/L` | Resize pane (repeatable, vim-style) |
| `Ctrl+a` then `q` | Quit entire session |
| Mouse click | Switch to clicked pane |
| Mouse drag border | Resize pane freely |

> **Tip:** Press `Ctrl+a` first, release, then press the action key.
>
> **Resize:** H/J/K/L are repeatable — press prefix once, then tap H/J/K/L multiple times. (H=left, J=down, K=up, L=right)

## Theme

Cyberpunk-inspired **Tokyo Night** color palette:

- Deep dark background (`#1a1b26`)
- Blue accent borders on active pane (`#7aa2f7`)
- Subtle inactive borders (`#3b4261`)
- Status bar with pane count and clock
- Pane numbers displayed in border headers

## System Monitor

The 9th pane automatically launches a system monitor. Vibe Terminal picks the best available tool:

| Priority | Tool | Notes |
|----------|------|-------|
| 1 | `btop` | Best visuals, install with `brew install btop` |
| 2 | `htop` | Classic, install with `brew install htop` |
| 3 | `vibe-monitor.sh` | Built-in custom monitor with Tokyo Night colors |
| 4 | `top` | Always available (macOS/Linux built-in) |

> **Tip:** Install `btop` for the best experience: `brew install btop`

## Files

```
~/vibe-term/
├── vibe-term.sh      # Main launcher script
├── vibe-term.conf    # tmux theme + keybindings config
├── vibe-monitor.sh   # Custom system monitor (fallback)
└── README.md
```

## Customization

Edit `vibe-term.conf` to customize:

- **Colors**: Change `pane-border-style` and `pane-active-border-style`
- **Status bar**: Modify `status-left` and `status-right` formats
- **Keybindings**: Add or modify `bind` commands
- **Prefix key**: Change `set -g prefix` (default: `Ctrl+a`)

## Troubleshooting

**"tmux not found"**
```bash
brew install tmux    # macOS
sudo apt install tmux  # Ubuntu/Debian
```

**Session already exists**
```bash
tmux kill-session -t vibe   # Kill existing session
vt                          # Relaunch
```

**Conflicts with existing tmux config**
Vibe Terminal uses its own isolated config file (`vibe-term.conf`), so it won't affect your `~/.tmux.conf`. However, if you're already inside a tmux session, you'll get a nested session.

## License

MIT

---

<p align="center">
  Made with 🎨 for vibe coders
</p>
