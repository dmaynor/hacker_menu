# Hacker Menu

A GTK4 power menu triggered by the Logitech MX Master 4 haptic thumb button. Built for Linux with Wayland/COSMIC support.

Pressing the haptic thumb button on the MX Master 4 pops up a dark-themed menu with dev/hacker actions.

## Menu Actions

| Action | Description |
|--------|-------------|
| Claude Code | Opens interactive Claude Code in a new terminal |
| Claude Selection | Sends highlighted text to Claude non-interactively |
| DPI Cycle | Cycles through 800/1200/1600/2400/3200 DPI |
| Screenshot OCR | Select screen region, OCR it, copy text to clipboard |
| Git Status | Show current git branch and status |
| Network Info | Show local/public IP, listening ports, VPN status |
| Clipboard Run | Execute clipboard contents as a shell command |
| Lock Screen | Lock the session |
| Kill Window | Click any window to kill it |
| Color Picker | Pick a color from screen (requires gpick) |
| Quick Note | Type a note, saved to ~/notes.txt with timestamp |
| System Monitor | Show CPU, memory, disk, temp, load average |

## Files

```
mouse-daemon.sh       # Daemon that listens for the haptic thumb button press
mouse-menu.sh         # Action dispatcher (runs the selected menu action)
mouse-menu-popup.py   # GTK4 popup menu UI
mouse-menu.service    # systemd user service for auto-start
99-mx-master4.rules   # udev rule for input device permissions
```

## Prerequisites

```bash
sudo apt install evtest python3-gi gir1.2-gtk-4.0 libnotify-bin \
    wl-clipboard xclip xdotool wofi tesseract-ocr
```

Optional:
```bash
sudo apt install gpick    # for Color Picker
```

Claude Code must be installed for the Claude actions:
https://docs.anthropic.com/en/docs/claude-code

## Mouse Setup

The MX Master 4 must be connected via **Bluetooth** (not the Bolt USB receiver). The Bolt receiver lacks kernel driver support on some distributions.

Pair via Bluetooth:
1. Long-press the Easy-Switch button on the mouse bottom (3 sec) until the LED blinks fast
2. Pair from your system:
```bash
bluetoothctl power on
bluetoothctl scan on
# Wait for "MX Master 4" to appear
bluetoothctl pair <MAC_ADDRESS>
bluetoothctl trust <MAC_ADDRESS>
bluetoothctl connect <MAC_ADDRESS>
```

### libratbag (optional, for DPI control)

The DPI Cycle action requires `ratbagctl` from [libratbag](https://github.com/libratbag/libratbag):

```bash
cd libratbag
meson builddir
ninja -C builddir
sudo ninja -C builddir install
sudo ldconfig
```

## Install

1. Copy scripts to `~/bin`:
```bash
mkdir -p ~/bin
cp mouse-daemon.sh mouse-menu.sh mouse-menu-popup.py ~/bin/
chmod +x ~/bin/mouse-daemon.sh ~/bin/mouse-menu.sh ~/bin/mouse-menu-popup.py
```

2. Install the udev rule (allows reading input events without sudo):
```bash
sudo cp 99-mx-master4.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG input $USER
```
Log out and back in for the group change to take effect.

3. Install the systemd user service:
```bash
mkdir -p ~/.config/systemd/user
cp mouse-menu.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable mouse-menu.service
systemctl --user start mouse-menu.service
```

## Usage

The daemon starts automatically on login. Press the **haptic thumb button** on the MX Master 4 to open the menu. Click an action or press Escape to dismiss.

### Manual control

```bash
# Check status
systemctl --user status mouse-menu

# Restart
systemctl --user restart mouse-menu

# Stop
systemctl --user stop mouse-menu

# View logs
journalctl --user -u mouse-menu

# Run manually (foreground)
~/bin/mouse-daemon.sh
```

## Customization

### Change the trigger button

Edit `mouse-daemon.sh` and change `BTN_BACK` to a different button event. Use `sudo evtest` to identify button codes on your mouse.

### Add menu items

1. Add the item label to the `items` list in `mouse-menu-popup.py`
2. Add a matching `case` block in `mouse-menu.sh`

### Change DPI presets

Edit the `PRESETS` array in the `DPI Cycle` case block in `mouse-menu.sh`:
```bash
PRESETS=(800 1200 1600 2400 3200)
```

### Change the menu theme

Edit the CSS in `mouse-menu-popup.py`:
```css
window { background: #1a1a2e; }
button { color: #e0e0e0; }
button:hover { background: #16213e; color: #00ff41; }
```

## Button Map (MX Master 4 via Bluetooth)

| Physical Button | Event Code | Description |
|----------------|------------|-------------|
| Left click | BTN_LEFT | Standard |
| Right click | BTN_RIGHT | Standard |
| Scroll wheel press | BTN_MIDDLE | Standard |
| Haptic thumb | BTN_BACK | **Triggers this menu** |
| Thumb forward | BTN_EXTRA | Browser forward |
| Thumb back | BTN_SIDE | Browser back |
| Ratchet toggle | (firmware) | Switches scroll mode |
| Scroll tilt L/R | REL_HWHEEL | Horizontal scroll |
