#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------
# Configuration (must match setup script)
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

# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------
log()   { echo -e "\e[1;34m[UNINSTALL]\e[0m $*"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $*"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

# ----------------------------------------------------------------------
# 1. Stop and disable battery timer
# ----------------------------------------------------------------------
if systemctl --user is-active --quiet system-sounds-battery.timer 2>/dev/null; then
    log "Stopping battery timer..."
    systemctl --user stop system-sounds-battery.timer
fi
if systemctl --user is-enabled --quiet system-sounds-battery.timer 2>/dev/null; then
    log "Disabling battery timer..."
    systemctl --user disable system-sounds-battery.timer
fi
log "Removing battery service and timer files..."
rm -f "$BATTERY_SERVICE" "$BATTERY_TIMER"
systemctl --user daemon-reload

# ----------------------------------------------------------------------
# 2. Stop and disable logoff service
# ----------------------------------------------------------------------
if systemctl --user is-active --quiet system-sounds-logoff.service 2>/dev/null; then
    log "Stopping logoff service..."
    systemctl --user stop system-sounds-logoff.service
fi
if systemctl --user is-enabled --quiet system-sounds-logoff.service 2>/dev/null; then
    log "Disabling logoff service..."
    systemctl --user disable system-sounds-logoff.service
fi
log "Removing logoff service file..."
rm -f "$LOGOFF_SERVICE"
systemctl --user daemon-reload

# ----------------------------------------------------------------------
# 3. Remove udev rule and helper (requires sudo)
# ----------------------------------------------------------------------
if [ -f "$UDEV_RULE_FILE" ] || [ -f "$UDEV_HELPER" ]; then
    read -p "Remove udev rules and helper script? (requires sudo) [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -f "$UDEV_RULE_FILE" "$UDEV_HELPER"
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        log "Removed udev rule and helper."
    else
        warn "Skipped udev removal."
    fi
fi

# ----------------------------------------------------------------------
# 4. Remove Hyprland config lines added by setup
# ----------------------------------------------------------------------
if [ -f "$HYPR_CONFIG" ]; then
    backup_file "$HYPR_CONFIG"
    log "Removing added lines from Hyprland config..."

    # Remove lines containing specific patterns
    sed -i '/exec-once.*notify_sound_listener.sh/d' "$HYPR_CONFIG"
    sed -i '/exec-once.*play_sound.sh logon/d' "$HYPR_CONFIG"

    log "Hyprland config cleaned."
else
    warn "Hyprland config not found. Skipping line removal."
fi

# ----------------------------------------------------------------------
# 5. Remove sound scripts and directory (optional)
# ----------------------------------------------------------------------
if [ -d "$SOUND_DIR" ]; then
    read -p "Remove all files and scripts in $SOUND_DIR? (Your sound files will be deleted!) [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$SOUND_DIR"
        log "Removed $SOUND_DIR and all contents."
    else
        warn "Sound directory kept. If you want to remove only the generated scripts, delete them manually."
    fi
fi

# ----------------------------------------------------------------------
# 6. Final message
# ----------------------------------------------------------------------
log "Uninstallation complete."
log "Please restart Hyprland (or log out/in) for all changes to take effect."
