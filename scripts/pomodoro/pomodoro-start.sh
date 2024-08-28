#!/usr/bin/env bash

SCRIPTS=~/linux-files/scripts
DURATION=$(cat $SCRIPTS/pomodoro/config/duration)

$SCRIPTS/pomodoro/pomodoro-end-break.sh

pomodoro start -d $DURATION
