#!/usr/bin/env bash

# Try xkb-switch (works if installed)
if command -v xkb-switch >/dev/null 2>&1; then
  out=$(xkb-switch -p 2>/dev/null)
  [ -n "$out" ] && { echo "{\"output\":\"$out\"}"; exit 0; }
fi

# Try setxkbmap (may work under Wayland with XWayland)
if command -v setxkbmap >/dev/null 2>&1; then
  out=$(setxkbmap -query 2>/dev/null | awk '/layout/{print $2}')
  [ -n "$out" ] && { echo "{\"output\":\"${out^^}\"}"; exit 0; }
fi

# Try localectl as fallback
if command -v localectl >/dev/null 2>&1; then
  out=$(localectl status 2>/dev/null | awk -F: '/X11 Layout/{gsub(/ /,\"\",$2); print $2}')
  [ -n "$out" ] && { echo "{\"output\":\"${out^^}\"}"; exit 0; }
fi

# Fallback: empty
echo '{"output":"--"}'

