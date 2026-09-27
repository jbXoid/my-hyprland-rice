#!/bin/sh

if ! pgrep -x hyprshot >/dev/null; then

    hyprshot -z -o $HYPRSHOT_DIR -m output

fi
