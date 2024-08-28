#!/usr/bin/env bash
SCRIPTS=~/linux-files/scripts

if $SCRIPTS/pomodoro/pomodoro-is-break.sh; then
	PID=$(pgrep -f "pomodoro break")
	kill $PID
fi
