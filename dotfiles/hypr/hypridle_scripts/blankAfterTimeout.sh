#!/usr/bin/env bash

sleep $1

if pgrep -x hyprlock >/dev/null; then
    echo "No hyprlock - no sweetie"
    hyprctl dispatch 'hl.dsp.dpms("off")'
fi
