#!/usr/bin/env bash

# User needs to know what layout they using
keymap_unformatted=$(hyprctl devices | grep keyboard -A 6 | grep "active keymap: ")
keymap=${keymap_unformatted##*'active keymap: '}
swayosd-client --custom-message "Keyboard: $keymap"

