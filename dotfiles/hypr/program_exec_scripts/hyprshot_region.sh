#!/bin/sh

if ! pgrep -x hyprpicker >/dev/null; then

    hyprshot -z -o $HYPRSHOT_DIR -m region

fi

