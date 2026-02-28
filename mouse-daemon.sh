#!/bin/bash
# MX Master 4 button daemon
# Haptic thumb button → power menu at cursor

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-detect MX Master 4 event device
DEVICE=$(grep -l "MX Master 4" /sys/class/input/event*/device/name 2>/dev/null | head -1 | grep -oP 'event\d+')
DEVICE="/dev/input/$DEVICE"

if [ ! -e "$DEVICE" ]; then
    echo "MX Master 4 not found"
    exit 1
fi
echo "Found MX Master 4 at $DEVICE"

# Capture display env so subprocesses can show GUI
export DISPLAY="${DISPLAY:-:1}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

echo "Mouse daemon started. PID $$"
echo "  Haptic thumb button → power menu"
echo "  Ctrl+C to stop"

# Try without sudo first (udev rule), fall back to sudo
if [ -r "$DEVICE" ]; then
    EVTEST="evtest"
else
    EVTEST="sudo evtest"
fi

$EVTEST "$DEVICE" 2>/dev/null | while read -r line; do
    if echo "$line" | grep -q "BTN_BACK.*value 1"; then
        "$SCRIPT_DIR/mouse-menu.sh" &
    fi
done
