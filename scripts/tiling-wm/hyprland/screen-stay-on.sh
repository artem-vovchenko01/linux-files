#!/usr/bin/env bash
# Turns the screen back on whenever it goes dark, the lock screen's blank
# included. With no signal, the HP 724pu sleeps after ~20 s and cuts its
# USB hub, and with it the wired network card. A 1 s check keeps it awake
# whatever its own power settings are.
set -u

while sleep 1; do
	hyprctl monitors -j 2>/dev/null | jq -e 'any(.[]; .disabled == false and .dpmsStatus == false)' >/dev/null || continue
	echo "screen went dark, turning it back on"
	hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null
done
