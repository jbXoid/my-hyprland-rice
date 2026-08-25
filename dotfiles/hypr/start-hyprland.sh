#!/usr/bin/env bash
# Wrapper to play logoff sound when Hyprland exits
trap '/home/jbxoid/.config/system_sounds/play_sound.sh logoff' EXIT
exec Hyprland "$@"
