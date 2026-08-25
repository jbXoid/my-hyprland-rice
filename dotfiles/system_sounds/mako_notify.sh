#!/usr/bin/env bash
# Called by Mako on-notify. Plays different sound based on urgency.
URGENCY="${MAKO_NOTIFICATION_URGENCY:-normal}"
if [ "$URGENCY" = "critical" ]; then
    exec "/home/jbxoid/.config/system_sounds/play_sound.sh" new_urgent_notification
else
    exec "/home/jbxoid/.config/system_sounds/play_sound.sh" new_notification
fi
