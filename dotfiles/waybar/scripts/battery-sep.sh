#!/bin/sh
if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
  echo "|"
fi

