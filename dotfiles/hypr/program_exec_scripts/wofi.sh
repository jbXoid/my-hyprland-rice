#!/bin/sh

# We dont need 5 wofi in a row (maybe someone needs but we don't)
if pgrep -x wofi >/dev/null; then
    pkill -x wofi
else
    wofi --show drun
fi

