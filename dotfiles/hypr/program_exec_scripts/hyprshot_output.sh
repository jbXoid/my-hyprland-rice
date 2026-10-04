#!/bin/sh

# If hyprshot is already running we dont need to execute it again
if ! pgrep -x hyprshot >/dev/null; then

    hyprshot -z -o $HYPRSHOT_DIR -m output

fi
