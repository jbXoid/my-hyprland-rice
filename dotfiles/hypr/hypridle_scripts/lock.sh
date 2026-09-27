#!/usr/bin/env bash
kbd="$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true).name')"
hyprctl switchxkblayout "$kbd" 0
ok
exec hyprlock

