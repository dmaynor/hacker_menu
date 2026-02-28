#!/bin/bash
# MX Master 4 Thumb Button Power Menu

export DISPLAY="${DISPLAY:-:1}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Kill any previous instance
pkill -f "mouse-menu-popup" 2>/dev/null
sleep 0.1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

choice=$(python3 "$SCRIPT_DIR/mouse-menu-popup.py" 2>/dev/null)

[ -z "$choice" ] && exit 0

case "$choice" in
    "Claude Code")
        # Open interactive Claude Code in a new terminal
        cosmic-term -e bash -c "unset CLAUDECODE; claude; exec bash" &
        ;;
    "Claude Commit")
        # Launch Claude Code with /commit skill
        cosmic-term -e bash -c "unset CLAUDECODE; echo '/commit' | claude; echo; echo 'Press Enter to close'; read" &
        ;;
    "Claude Simplify")
        # Launch Claude Code with /simplify skill
        cosmic-term -e bash -c "unset CLAUDECODE; echo '/simplify' | claude; echo; echo 'Press Enter to close'; read" &
        ;;
    "Claude Selection")
        # Grab selected text, send to claude non-interactively, show result
        selection=$(wl-paste -p 2>/dev/null || xclip -selection primary -o 2>/dev/null)
        if [ -n "$selection" ]; then
            tmpf="/tmp/.claude-selection-$$"
            echo "$selection" > "$tmpf"
            cosmic-term -e bash -c "unset CLAUDECODE; claude -p \"Explain or help with this:\" < \"$tmpf\"; rm -f \"$tmpf\"; echo; echo 'Press Enter to close'; read" &
        else
            notify-send -t 2000 "No text selected — highlight some text first"
        fi
        ;;
    "DPI Cycle")
        PRESETS=(800 1200 1600 2400 3200)
        STATE="/tmp/.dpi-state"
        current=$(cat "$STATE" 2>/dev/null || echo 0)
        next=$(( (current + 1) % ${#PRESETS[@]} ))
        dpi=${PRESETS[$next]}
        ratbagctl sobbing-paca dpi set "$dpi" 2>/dev/null
        echo "$next" > "$STATE"
        notify-send -t 1500 "DPI: $dpi"
        ;;
    "Screenshot OCR")
        tmp="/tmp/ocr-$(date +%s).png"
        gnome-screenshot -a -f "$tmp" 2>/dev/null
        if [ -f "$tmp" ]; then
            text=$(tesseract "$tmp" - 2>/dev/null)
            echo -n "$text" | xclip -selection clipboard
            notify-send -t 3000 "OCR Copied" "$text"
        fi
        ;;
    "Git Status")
        info=$(git -C "$HOME/code/libratbag" status -sb 2>/dev/null || echo "No git repo found")
        notify-send -t 5000 "Git Status" "$info"
        ;;
    "Network Info")
        ip=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | head -3)
        pubip=$(curl -s --max-time 2 ifconfig.me)
        ports=$(ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | tail -5)
        vpn=$(ip link show | grep -E "tun|wg|vpn" | awk -F: '{print $2}' | tr -d ' ')
        notify-send -t 8000 "Network" "Local: ${ip:-none}\nPublic: ${pubip:-timeout}\nListening:\n${ports:-none}\nVPN: ${vpn:-none}"
        ;;
    "Clipboard Run")
        cmd=$(xclip -selection clipboard -o 2>/dev/null)
        if [ -n "$cmd" ]; then
            output=$(eval "$cmd" 2>&1 | head -20)
            notify-send -t 5000 "$ $cmd" "$output"
        else
            notify-send -t 2000 "Clipboard empty"
        fi
        ;;
    "Lock Screen")
        loginctl lock-session
        ;;
    "Kill Window")
        notify-send -t 2000 "Click a window to kill..."
        xkill
        ;;
    "Color Picker")
        if command -v gpick &>/dev/null; then
            gpick -s -o 2>/dev/null | xclip -selection clipboard
        else
            notify-send -t 2000 "Install gpick: sudo apt install gpick"
        fi
        ;;
    "Quick Note")
        note=$(echo "" | wofi --dmenu --prompt "Note:" --width 500 --cache-file /dev/null 2>/dev/null)
        if [ -n "$note" ]; then
            echo "$(date '+%Y-%m-%d %H:%M') | $note" >> "$HOME/notes.txt"
            notify-send -t 2000 "Saved to ~/notes.txt"
        fi
        ;;
    "System Monitor")
        cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
        mem=$(free -h | awk '/Mem:/{printf "%s/%s", $3, $2}')
        disk=$(df -h / | awk 'NR==2{printf "%s/%s", $3, $2}')
        temp=$(sensors 2>/dev/null | grep -oP 'Package.*?\+\K[0-9.]+' | head -1)
        load=$(uptime | awk -F'load average:' '{print $2}')
        notify-send -t 5000 "System" "CPU: ${cpu}%\nMem: ${mem}\nDisk: ${disk}\nTemp: ${temp:-n/a}°C\nLoad:${load}"
        ;;
esac
