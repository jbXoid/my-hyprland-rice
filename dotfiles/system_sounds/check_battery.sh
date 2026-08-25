#!/usr/bin/env bash
# Exit silently if no battery is present
if [ ! -d /sys/class/power_supply/BAT* ]; then
    exit 0
fi

BATTERY_LEVEL=""
# Try upower first
if command -v upower >/dev/null 2>&1; then
    for bat in /org/freedesktop/UPower/devices/battery_*; do
        LEVEL=$(upower -i "$bat" 2>/dev/null | grep percentage | awk '{print $2}' | tr -d '%')
        if [ -n "$LEVEL" ]; then
            BATTERY_LEVEL="$LEVEL"
            break
        fi
    done
fi

# Fallback to sysfs
if [ -z "$BATTERY_LEVEL" ]; then
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "$bat/capacity" ]; then
            BATTERY_LEVEL=$(cat "$bat/capacity")
            break
        fi
    done
fi

# Still no battery? exit
[ -z "$BATTERY_LEVEL" ] && exit 0

if [ "$BATTERY_LEVEL" -le 10 ]; then
    "/home/jbxoid/.config/system_sounds/play_sound.sh" battery_critical
elif [ "$BATTERY_LEVEL" -le 20 ]; then
    "/home/jbxoid/.config/system_sounds/play_sound.sh" battery_low
fi
