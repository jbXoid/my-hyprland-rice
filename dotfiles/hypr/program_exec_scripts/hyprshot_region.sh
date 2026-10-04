#!/bin/sh

# If hyprshot is already running we don't to exec it again
if ! pgrep -x hyprpicker >/dev/null; then

    hyprshot -z -o $HYPRSHOT_DIR -m region

fi

