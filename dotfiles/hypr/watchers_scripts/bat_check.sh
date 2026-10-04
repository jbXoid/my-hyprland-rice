#!/usr/bin/env bash
set -euo pipefail

LOW1=20
LOW2=15
CRIT1=10
CRIT2=5

wasLow=0

while :
do

# Getting battery percentage
cap_float=$(upower -i $(upower -e | grep BAT) | grep "percentage:" | tr -d "percentage:" | tr -d " " | tr -d "%")
cap=${cap_float%.*}

# Checking percentage
if [ "$cap" -lt "$LOW1" ] && [ $wasLow != 1 ]
then
	echo "Low battery: >$LOW1"
	swayosd-client --custom-message "Low battery: >$LOW1"
	
	wasLow=1

elif [ "$cap" -lt "$LOW2" ] && [ "$wasLow" -ne 2 ]
then
	echo "Low battery: >$LOW2"
	swayosd-client --custom-message "Low battery: >$LOW2"

	wasLow=2

elif [ "$cap" -lt "$CRIT1" ] && [ "$wasLow" -ne 2 ]
then
	echo "Crit battery: >$CRIT1"
	swayosd-client --custom-message "CRITICAL BATTERY: >$CRIT1"

	wasLow=3

elif [ "$cap" -lt "$CRIT2" ] && [ "$wasLow" -ne 3 ]
then
	echo "Crit battery: >$CRIT2"
	swayosd-client --custom-message "CRITICAL BATTERY: >$CRIT2"

	wasLow=4

fi

sleep 1
done
