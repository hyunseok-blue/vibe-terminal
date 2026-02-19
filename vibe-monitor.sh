#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  🖥️  Vibe Monitor - Tokyo Night 테마 시스템 모니터
#  btop/htop 없을 때 사용하는 커스텀 폴백 모니터
# ═══════════════════════════════════════════════════════════════

set -euo pipefail
trap 'tput cnorm 2>/dev/null; exit 0' INT TERM

# ── Tokyo Night Colors (ANSI 256) ────────────────────────────
BLUE="\033[38;5;111m"
PURPLE="\033[38;5;141m"
CYAN="\033[38;5;117m"
GREEN="\033[38;5;149m"
RED="\033[38;5;210m"
YELLOW="\033[38;5;179m"
TEXT="\033[38;5;146m"
DIM="\033[38;5;60m"
BOLD="\033[1m"
RESET="\033[0m"

OS="$(uname)"

# ── Bar Drawing ──────────────────────────────────────────────
draw_bar() {
    local percent=$1
    local width=${2:-20}
    local color

    if ((percent >= 80)); then
        color="$RED"
    elif ((percent >= 60)); then
        color="$YELLOW"
    else
        color="$GREEN"
    fi

    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))

    printf "${color}"
    for ((i = 0; i < filled; i++)); do printf "█"; done
    printf "${DIM}"
    for ((i = 0; i < empty; i++)); do printf "░"; done
    printf "${RESET} ${TEXT}%3d%%${RESET}" "$percent"
}

# ── CPU Usage ────────────────────────────────────────────────
get_cpu() {
    if [[ "$OS" == "Darwin" ]]; then
        local cpu_line
        cpu_line=$(top -l 2 -n 0 -s 1 2>/dev/null | grep -m1 "CPU usage" | tail -1)
        local user sys
        user=$(echo "$cpu_line" | awk '{print $3}' | tr -d '%')
        sys=$(echo "$cpu_line" | awk '{print $5}' | tr -d '%')
        echo "${user%%.*} ${sys%%.*}"
    else
        local line1 line2
        line1=$(head -1 /proc/stat)
        sleep 1
        line2=$(head -1 /proc/stat)
        local idle1 total1 idle2 total2
        idle1=$(echo "$line1" | awk '{print $5}')
        total1=$(echo "$line1" | awk '{sum=0; for(i=2;i<=NF;i++) sum+=$i; print sum}')
        idle2=$(echo "$line2" | awk '{print $5}')
        total2=$(echo "$line2" | awk '{sum=0; for(i=2;i<=NF;i++) sum+=$i; print sum}')
        local diff_idle=$(( idle2 - idle1 ))
        local diff_total=$(( total2 - total1 ))
        local usage=$(( (diff_total - diff_idle) * 100 / diff_total ))
        echo "$usage 0"
    fi
}

# ── Memory Usage ─────────────────────────────────────────────
get_memory() {
    if [[ "$OS" == "Darwin" ]]; then
        local page_size
        page_size=$(vm_stat | head -1 | grep -o '[0-9]*')
        local active wired total_bytes
        active=$(vm_stat | awk '/Pages active/ {print $NF}' | tr -d '.')
        wired=$(vm_stat | awk '/Pages wired/ {print $NF}' | tr -d '.')
        total_bytes=$(sysctl -n hw.memsize)
        local used_bytes=$(( (active + wired) * page_size ))
        local total_gb=$(( total_bytes / 1073741824 ))
        local used_gb_x10=$(( used_bytes * 10 / 1073741824 ))
        local percent=$(( used_bytes * 100 / total_bytes ))
        echo "$percent $used_gb_x10 $total_gb"
    else
        local total avail
        total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        local used=$(( total - avail ))
        local percent=$(( used * 100 / total ))
        local used_gb_x10=$(( used * 10 / 1048576 ))
        local total_gb=$(( total / 1048576 ))
        echo "$percent $used_gb_x10 $total_gb"
    fi
}

# ── Disk Usage ───────────────────────────────────────────────
get_disk() {
    df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5, $3, $2}'
}

# ── Load Average ─────────────────────────────────────────────
get_load() {
    if [[ "$OS" == "Darwin" ]]; then
        sysctl -n vm.loadavg | awk '{print $1, $2, $3}'
    else
        awk '{print $1, $2, $3}' /proc/loadavg
    fi
}

# ── Top Processes ────────────────────────────────────────────
get_processes() {
    if [[ "$OS" == "Darwin" ]]; then
        ps -Arco pid,%cpu,%mem,comm 2>/dev/null | head -6
    else
        ps aux --sort=-%cpu 2>/dev/null | awk 'NR<=6 {printf "%-8s %5s %5s %s\n", $2, $3, $4, $11}'
    fi
}

# ── Render ───────────────────────────────────────────────────
render() {
    tput cup 0 0
    tput civis  # hide cursor

    local cols
    cols=$(tput cols 2>/dev/null || echo 60)

    # Header
    printf "\n"
    printf "  ${BLUE}${BOLD}╔══════════════════════════════════════╗${RESET}\n"
    printf "  ${BLUE}${BOLD}║${RESET}  ${PURPLE}${BOLD}▀▄▀${RESET} ${CYAN}${BOLD}VIBE MONITOR${RESET} ${PURPLE}${BOLD}▀▄▀${RESET}              ${BLUE}${BOLD}║${RESET}\n"
    printf "  ${BLUE}${BOLD}╚══════════════════════════════════════╝${RESET}\n"
    printf "\n"

    # CPU
    local cpu_data
    cpu_data=$(get_cpu)
    local user_pct sys_pct total_cpu
    user_pct=$(echo "$cpu_data" | awk '{print $1}')
    sys_pct=$(echo "$cpu_data" | awk '{print $2}')
    total_cpu=$(( user_pct + sys_pct ))
    ((total_cpu > 100)) && total_cpu=100

    printf "  ${CYAN}${BOLD} CPU${RESET}  "
    draw_bar "$total_cpu" 25
    printf "  ${DIM}usr:${user_pct}%% sys:${sys_pct}%%${RESET}\n"
    printf "\n"

    # Memory
    local mem_data
    mem_data=$(get_memory)
    local mem_pct used_x10 total_gb
    mem_pct=$(echo "$mem_data" | awk '{print $1}')
    used_x10=$(echo "$mem_data" | awk '{print $2}')
    total_gb=$(echo "$mem_data" | awk '{print $3}')
    local used_int=$(( used_x10 / 10 ))
    local used_dec=$(( used_x10 % 10 ))

    printf "  ${PURPLE}${BOLD} MEM${RESET}  "
    draw_bar "$mem_pct" 25
    printf "  ${DIM}${used_int}.${used_dec}G / ${total_gb}G${RESET}\n"
    printf "\n"

    # Disk
    local disk_data
    disk_data=$(get_disk)
    local disk_pct disk_used disk_total
    disk_pct=$(echo "$disk_data" | awk '{print $1}')
    disk_used=$(echo "$disk_data" | awk '{print $2}')
    disk_total=$(echo "$disk_data" | awk '{print $3}')

    printf "  ${YELLOW}${BOLD} DSK${RESET}  "
    draw_bar "$disk_pct" 25
    printf "  ${DIM}${disk_used} / ${disk_total}${RESET}\n"
    printf "\n"

    # Load Average
    local load_data
    load_data=$(get_load)
    local l1 l5 l15
    l1=$(echo "$load_data" | awk '{print $1}')
    l5=$(echo "$load_data" | awk '{print $2}')
    l15=$(echo "$load_data" | awk '{print $3}')

    printf "  ${GREEN}${BOLD} LOAD${RESET} ${TEXT}${l1}${RESET} ${DIM}(1m)${RESET}  ${TEXT}${l5}${RESET} ${DIM}(5m)${RESET}  ${TEXT}${l15}${RESET} ${DIM}(15m)${RESET}\n"
    printf "\n"

    # Separator
    printf "  ${DIM}"
    for ((i = 0; i < 40 && i < cols - 4; i++)); do printf "─"; done
    printf "${RESET}\n"
    printf "\n"

    # Top Processes
    printf "  ${CYAN}${BOLD} TOP PROCESSES${RESET}\n"
    printf "  ${DIM}%-8s %5s %5s %s${RESET}\n" "PID" "CPU%" "MEM%" "COMMAND"

    local first=true
    while IFS= read -r line; do
        if $first; then
            first=false
            continue
        fi
        printf "  ${TEXT}${line}${RESET}\n"
    done <<< "$(get_processes)"

    # Footer
    printf "\n"
    printf "  ${DIM}↻ 2s refresh │ q: quit pane │ Ctrl+a f: zoom${RESET}\n"

    # Clear remaining lines
    tput el
    for ((i = 0; i < 5; i++)); do
        printf "\n"
        tput el
    done
}

# ── Main Loop ────────────────────────────────────────────────
clear
while true; do
    render
    sleep 2
done
