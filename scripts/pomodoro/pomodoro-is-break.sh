#!/usr/bin/env bash
SCRIPTS=~/linux-files/scripts
CUSTOM_SETUP=~/custom-setup

if [[ "$(cat $CUSTOM_SETUP/pomodoro/state)" == "break" ]]; then
  exit 0
else
  exit 1
fi

#if [ -n "$(ps -ef | grep 'pomodoro break' | head -n -1)" ]; then
#  exit 0
#else
#  exit 1
#fi
