#!/usr/bin/env bash
set -x
kill $(pgrep -f pomodoro-check-user-idle-on-break.sh | grep -v $$)
SCRIPTS=~/linux-files/scripts
CUSTOM_SETUP=~/custom-setup

FIRST_REMIND_AFTER=$(cat $SCRIPTS/pomodoro/config/check_user_activity_ping_after_seconds)
REMINDER_GAP=$(cat $SCRIPTS/pomodoro/config/check_user_activity_reminder_gap)

while true; do
  if $SCRIPTS/pomodoro/pomodoro-is-break.sh; then
    
    if ! $SCRIPTS/hyprland/is-user-idle.sh; then
      BREAK_STARTED=$(stat -c %Y $CUSTOM_SETUP/pomodoro/pomodoro_break_started_touch_timestamp)
      TIME_NOW=$(date +%s)
      TIME_PASSED=$(( $TIME_NOW - $BREAK_STARTED ))

      if [[ "$TIME_PASSED" -gt "$FIRST_REMIND_AFTER" ]]; then
        # Remove previous dialog if it's present
        zenity --warning --text "Break is in progress! Stop working!" &
        sleep $REMINDER_GAP
        pkill zenity
      fi

    fi

  fi
done
