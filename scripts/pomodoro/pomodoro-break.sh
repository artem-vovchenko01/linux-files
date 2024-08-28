#!/usr/bin/env bash
SCRIPTS=~/linux-files/scripts
CUSTOM_SETUP=~/custom-setup

DURATION=$(cat $SCRIPTS/pomodoro/config/break_duration)

if $SCRIPTS/pomodoro/pomodoro-is-break.sh; then
	notify-send "Pomodoro break is already in progress"
else
	pomodoro finish
	pomodoro break $DURATION | tee $CUSTOM_SETUP/hyprland/pomodoro/pomodoro_break_status &
	wait
	echo break_ended > $CUSTOM_SETUP/hyprland/pomodoro/state
	# $SCRIPTS/sound-random.sh
fi
