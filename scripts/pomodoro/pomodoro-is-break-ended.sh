#!/usr/bin/env bash
SCRIPTS=~/linux-files/scripts
CUSTOM_SETUP=~/custom-setup

if [[ "$(cat $CUSTOM_SETUP/pomodoro/state)" == "break_ended" ]]; then
  exit 0
else
  exit 1
fi
