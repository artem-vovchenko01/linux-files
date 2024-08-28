#!/usr/bin/env bash
STATUS=$(pomodoro status)
# We can't check this using "state" file, because writing to the "state" file about state "ended" relies on this script. Writing is done from status script
if grep -q $'\u2757' <(echo $STATUS); then
  exit 0
else
  exit 1
fi
