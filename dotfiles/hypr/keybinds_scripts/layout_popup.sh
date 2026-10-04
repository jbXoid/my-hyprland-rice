#!/usr/bin/env bash

# User needs to know what layout they using
layout="$(hyprctl devices | awk '/active keymap/ {print $3; exit}')"
swayosd-client --custom-message "Keyboard: $layout"

