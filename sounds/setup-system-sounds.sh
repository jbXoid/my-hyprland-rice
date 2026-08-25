#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------
SOUND_DIR="$HOME/.config/system_sounds"
PLAYER_SCRIPT="$SOUND_DIR/play_sound.sh"
NOTIFY_LISTENER="$SOUND_DIR/notify_sound_listener.sh"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"
UDEV_RULE_FILE="/etc/udev/rules.d/99-system-sounds.rules"
UDEV_HELPER="/usr/local/bin/system-sound-udev-helper"
BATTERY_SERVICE="$HOME/.config/systemd/user/system-sounds-battery.service"
BATTERY_TIMER="$HOME/.config/systemd/user/system-sounds-battery.timer"
BATTERY_SCRIPT="$SOUND_DIR/check_battery.sh"
LOGOFF_SERVICE="$HOME/.config/systemd/user/system-sounds-logoff.service"
LOW_BATTERY=20
CRITICAL_BATTERY=10

# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------
log()   { echo -e "\e[1;32m[SETUP]\e[0m $*"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $*"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"
        log "Backed up $file"
    fi
}

# Detect audio player
if command -v pw-play >/dev/null 2>&1; then
    AUDIO_PLAYER="pw-play"
elif command -v paplay >/dev/null 2>&1; then
    AUDIO_PLAYER="paplay"
else
    warn "Neither pw-play nor paplay found. Sound playback may not work."
    AUDIO_PLAYER="paplay"
fi

# ----------------------------------------------------------------------
# 1. Create sound directory and player script
# ----------------------------------------------------------------------
mkdir -p "$SOUND_DIR"
log "Using sound directory: $SOUND_DIR"

cat > "$PLAYER_SCRIPT" <<EOF
#!/usr/bin/env bash
# Play a sound from $SOUND_DIR
SOUND_NAME="\$1"
SOUND_DIR="$SOUND_DIR"
AUDIO_PLAYER="$AUDIO_PLAYER"

if [ -z "\$SOUND_NAME" ]; then
    echo "Usage: \$0 <sound_name>" >&2
    exit 1
fi

SOUND_FILE=""
for ext in ogg wav mp3 flac; do
    if [ -f "\$SOUND_DIR/\$SOUND_NAME.\$ext" ]; then
        SOUND_FILE="\$SOUND_DIR/\$SOUND_NAME.\$ext"
        break
    fi
done

if [ -z "\$SOUND_FILE" ]; then
    echo "Sound file not found: \$SOUND_DIR/\$SOUND_NAME.*" >&2
    exit 1
fi

exec \$AUDIO_PLAYER "\$SOUND_FILE"
EOF
chmod +x "$PLAYER_SCRIPT"
log "Created player script: $PLAYER_SCRIPT"

# ----------------------------------------------------------------------
# 2. Notification sounds via D-Bus monitor (no Mako config changes)
# ----------------------------------------------------------------------
cat > "$NOTIFY_LISTENER" <<EOF
#!/usr/bin/env bash
# Listen for notifications and play sounds
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" |
while read -r line; do
    if echo "\$line" | grep -q "uint32 2"; then
        "$PLAYER_SCRIPT" new_urgent_notification
    else
        "$PLAYER_SCRIPT" new_notification
    fi
done
EOF
chmod +x "$NOTIFY_LISTENER"
log "Created notification listener: $NOTIFY_LISTENER"

# Ensure Hyprland config exists
if [ ! -f "$HYPR_CONFIG" ]; then
    mkdir -p "$(dirname "$HYPR_CONFIG")"
    touch "$HYPR_CONFIG"
    log "Created empty Hyprland config: $HYPR_CONFIG"
fi

# Add listener to autostart if not present
if ! grep -q "exec-once.*notify_sound_listener.sh" "$HYPR_CONFIG"; then
    echo "exec-once = $NOTIFY_LISTENER" >> "$HYPR_CONFIG"
    log "Added notification listener to Hyprland autostart."
else
    log "Notification listener already in autostart."
fi

# ----------------------------------------------------------------------
# 3. Hyprland: logon sound
# ----------------------------------------------------------------------
if ! grep -q "exec-once.*play_sound.sh logon" "$HYPR_CONFIG"; then
    echo "exec-once = $PLAYER_SCRIPT logon" >> "$HYPR_CONFIG"
    log "Added logon sound to Hyprland config."
else
    log "Logon sound already present."
fi

# ----------------------------------------------------------------------
# 4. Logoff sound via systemd user service (no wrapper)
# ----------------------------------------------------------------------
echo ""
echo "Do you want to enable the logoff sound?"
echo "This uses a systemd user service and does NOT affect your login method."
read -p "Enable logoff sound? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$LOGOFF_SERVICE")"
    cat > "$LOGOFF_SERVICE" <<EOF
[Unit]
Description=Play logoff sound when user session ends

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=$PLAYER_SCRIPT logoff

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now system-sounds-logoff.service
    log "Enabled logoff sound service. It will play when you log out or shut down."
else
    log "Skipped logoff sound setup."
fi

# ----------------------------------------------------------------------
# 5. Udev rules for USB device sounds (with embedded username and cooldown)
# ----------------------------------------------------------------------
echo ""
read -p "Install udev rules for USB connect/disconnect sounds? (requires sudo) [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Detect current user (should be the one running the script)
    CURRENT_USER="$USER"
    if [ -z "$CURRENT_USER" ]; then
        error "Could not determine your username. Please run this script as your normal user (not root)."
    fi
    log "Setting up udev helper for user: $CURRENT_USER"

    # Create helper script with hardcoded username and cooldown
    sudo tee "$UDEV_HELPER" > /dev/null <<EOF
#!/usr/bin/env bash
# Helper for udev to play sound as the logged-in user with cooldown
USER_NAME="$CURRENT_USER"
USER_UID=\$(id -u "\$USER_NAME")
if [ -z "\$USER_UID" ]; then
    exit 0
fi

export XDG_RUNTIME_DIR="/run/user/\$USER_UID"
export HOME="/home/\$USER_NAME"
export DBUS_SESSION_BUS_ADDRESS="unix:path=\$XDG_RUNTIME_DIR/bus"

# Cooldown: ignore same event type if it occurred within the last 3 seconds
COOLDOWN_FILE="/tmp/system-sound-udev-\$1.timestamp"
if [ -f "\$COOLDOWN_FILE" ]; then
    last=\$(cat "\$COOLDOWN_FILE")
    now=\$(date +%s)
    if [ \$((now - last)) -lt 3 ]; then
        exit 0
    fi
fi
date +%s > "\$COOLDOWN_FILE"

# Use runuser to drop privileges and play sound
runuser -u "\$USER_NAME" -- /home/\$USER_NAME/.config/system_sounds/play_sound.sh "\$1"
EOF
    sudo chmod +x "$UDEV_HELPER"

    # Simple udev rule (matches all USB events, cooldown prevents duplicates)
    sudo tee "$UDEV_RULE_FILE" > /dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="usb", RUN+="/usr/local/bin/system-sound-udev-helper device_connected"
ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/local/bin/system-sound-udev-helper device_disconnected"
EOF

    # Reload udev rules and trigger
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    log "Installed udev rules. USB sounds will play once per device (with cooldown)."
else
    warn "Skipped udev rule installation."
fi

# ----------------------------------------------------------------------
# 6. Battery low/critical via systemd user timer (auto‑disable if no battery)
# ----------------------------------------------------------------------
cat > "$BATTERY_SCRIPT" <<EOF
#!/usr/bin/env bash
# Exit silently if no battery is present
if [ ! -d /sys/class/power_supply/BAT* ]; then
    exit 0
fi

BATTERY_LEVEL=""
# Try upower first
if command -v upower >/dev/null 2>&1; then
    for bat in /org/freedesktop/UPower/devices/battery_*; do
        LEVEL=\$(upower -i "\$bat" 2>/dev/null | grep percentage | awk '{print \$2}' | tr -d '%')
        if [ -n "\$LEVEL" ]; then
            BATTERY_LEVEL="\$LEVEL"
            break
        fi
    done
fi

# Fallback to sysfs
if [ -z "\$BATTERY_LEVEL" ]; then
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "\$bat/capacity" ]; then
            BATTERY_LEVEL=\$(cat "\$bat/capacity")
            break
        fi
    done
fi

# Still no battery? exit
[ -z "\$BATTERY_LEVEL" ] && exit 0

if [ "\$BATTERY_LEVEL" -le $CRITICAL_BATTERY ]; then
    "$PLAYER_SCRIPT" battery_critical
elif [ "\$BATTERY_LEVEL" -le $LOW_BATTERY ]; then
    "$PLAYER_SCRIPT" battery_low
fi
EOF
chmod +x "$BATTERY_SCRIPT"

mkdir -p "$(dirname "$BATTERY_SERVICE")"
cat > "$BATTERY_SERVICE" <<EOF
[Unit]
Description=Check battery level and play sound

[Service]
Type=oneshot
ExecStart=$BATTERY_SCRIPT
EOF

cat > "$BATTERY_TIMER" <<EOF
[Unit]
Description=Run battery sound check every minute

[Timer]
OnCalendar=*-*-* *:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now system-sounds-battery.timer
log "Battery monitoring timer started. It will automatically skip if no battery is present."

# ----------------------------------------------------------------------
# 7. Final summary
# ----------------------------------------------------------------------
log "Setup complete!"
log "  Sound directory: $SOUND_DIR"
log "  Notification sounds: via D-Bus listener (no Mako changes)."
log "  Logon sound: added to Hyprland autostart."
log "  Logoff sound: $([ -f "$LOGOFF_SERVICE" ] && echo "enabled (systemd service)" || echo "disabled")"
log "  USB device sounds: $([ -f "$UDEV_RULE_FILE" ] && echo "installed" || echo "skipped")"
log "  Battery sounds: timer active, auto-disables if no battery."
warn "Place your sound files in $SOUND_DIR with names like: new_notification.ogg, device_connected.wav, etc."
