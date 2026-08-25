#!/usr/bin/env bash
# Listen for notifications and play sounds
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" |
while read -r line; do
    if echo "$line" | grep -q "uint32 2"; then
        "/home/jbxoid/.config/system_sounds/play_sound.sh" new_urgent_notification
    else
        "/home/jbxoid/.config/system_sounds/play_sound.sh" new_notification
    fi
done
