#!/usr/bin/env bash

SCRIPTS=~/linux-files/scripts

if $SCRIPTS/pomodoro/pomodoro-is-enabled.sh; then
  notify-send "Pomodoro already enabled"
  exit
fi

$SCRIPTS/pomodoro/pomodoro-enable.sh
$SCRIPTS/pomodoro/pomodoro-start.sh
