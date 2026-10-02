#!/usr/bin/env bash
set -euo pipefail

# 1) Media playing?
if playerctl -a status 2>/dev/null | grep -q Playing; then
  exit 0
  echo "Something is playing"
fi

# 2) Any fullscreen window?
if hyprctl -j clients | jq -e '.[] | select(.fullscreen == true)' >/dev/null; then
  exit 0
  echo "Something is fullscreen"
fi

# 3) Kitty running / focused
focused_class="$(hyprctl -j activewindow | jq -r '.class // empty')"
if [ "$focused_class" = "kitty" ]; then
  exit 0
  echo "Kitty is focused"
fi

# no blocker -> blank
echo "Seems that user completetly forgot about computer"
hyprctl dispatch 'hl.dsp.dpms("off")'
