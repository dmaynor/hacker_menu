#!/bin/bash
# Hacker Menu installer
# Installs all dependencies, copies scripts, and enables the systemd service

set -e

echo "=== Hacker Menu Installer ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Dependencies ---
echo "[1/5] Installing system packages..."
sudo apt install -y \
    evtest \
    python3-gi \
    gir1.2-gtk-4.0 \
    libnotify-bin \
    wl-clipboard \
    xclip \
    wofi \
    tesseract-ocr \
    gnome-screenshot \
    x11-utils \
    curl \
    git \
    lm-sensors \
    gpick \
    2>&1 | tail -1

# --- Claude Code ---
echo ""
echo "[2/5] Checking Claude Code..."
if command -v claude &>/dev/null; then
    echo "  Claude Code already installed: $(claude --version 2>&1 | head -1)"
else
    echo "  Claude Code not found."
    if command -v npm &>/dev/null; then
        read -p "  Install Claude Code via npm? [y/N] " yn
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            npm install -g @anthropic-ai/claude-code
        fi
    else
        echo "  Install npm first, then run: npm install -g @anthropic-ai/claude-code"
        echo "  See: https://docs.anthropic.com/en/docs/claude-code"
    fi
fi

# --- libratbag (for DPI Cycle) ---
echo ""
echo "[3/5] Checking ratbagctl..."
if command -v ratbagctl &>/dev/null; then
    echo "  ratbagctl already installed"
else
    echo "  ratbagctl not found. DPI Cycle will not work without it."
    echo "  Install from: https://github.com/libratbag/libratbag"
fi

# --- Copy scripts ---
echo ""
echo "[4/5] Installing scripts to ~/bin..."
mkdir -p ~/bin
cp "$SCRIPT_DIR/mouse-daemon.sh" ~/bin/
cp "$SCRIPT_DIR/mouse-menu.sh" ~/bin/
cp "$SCRIPT_DIR/mouse-menu-popup.py" ~/bin/
chmod +x ~/bin/mouse-daemon.sh ~/bin/mouse-menu.sh ~/bin/mouse-menu-popup.py
echo "  Copied to ~/bin/"

# --- udev rule ---
echo ""
echo "  Installing udev rule..."
sudo cp "$SCRIPT_DIR/99-mx-master4.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

if ! groups | grep -q input; then
    sudo usermod -aG input "$USER"
    echo "  Added $USER to input group (log out and back in to take effect)"
fi

# --- systemd service ---
echo ""
echo "[5/5] Setting up systemd service..."
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/mouse-menu.service << EOF
[Unit]
Description=MX Master 4 Haptic Thumb Button Menu Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=$HOME/bin/mouse-daemon.sh
Restart=on-failure
RestartSec=5
Environment=DISPLAY=:1
Environment=WAYLAND_DISPLAY=wayland-0
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable mouse-menu.service
systemctl --user start mouse-menu.service

echo ""
echo "=== Done ==="
echo ""
echo "Press the haptic thumb button on your MX Master 4 to open the menu."
echo ""
echo "Commands:"
echo "  systemctl --user status mouse-menu    # check status"
echo "  systemctl --user restart mouse-menu   # restart"
echo "  systemctl --user stop mouse-menu      # stop"
echo "  journalctl --user -u mouse-menu       # view logs"
