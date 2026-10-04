#!/bin/bash

# Very interesting and annoying bug that swayosd-server not always reacts on call commands, so I came up with this weird fix, but it works, so I won't touch it XD

pkill -9 -x swayosd-server
swayosd-server &>/dev/null &
sleep 0.05

swayosd-client "$@"
