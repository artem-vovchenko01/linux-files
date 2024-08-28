#!/usr/bin/env bash

SCRIPTS=~/linux-files/scripts
DURATION=$(cat $SCRIPTS/pomodoro/config/prolongue_duration)

$SCRIPTS/pomodoro/pomodoro-end-break.sh

pomodoro start -d $DURATION
