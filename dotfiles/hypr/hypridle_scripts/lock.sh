#!/usr/bin/env bash
if [ "$(playerctl status)" != "Playing" ]; then
  hyprlock
fi
