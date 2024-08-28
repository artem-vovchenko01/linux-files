#!/usr/bin/env bash
set -x
SCRIPTS=~/linux-files/scripts
CUSTOM_SETUP=~/custom-setup

PROLONGUE_DURATION=$(cat $SCRIPTS/pomodoro/config/prolongue_duration)
STATUS=$(pomodoro status)

echo -en "\U1f345 $(cat $CUSTOM_SETUP/pomodoro/state) | "

# disabled
if ! $SCRIPTS/pomodoro/pomodoro-is-enabled.sh; then
	echo -n disabled
	exit
fi

# pomodoro ended -> do break
# first we need to check if pomodoro have ended. Because state file will contain "running" if we don't check if pomodoro ended
if $SCRIPTS/pomodoro/pomodoro-is-ended.sh; then
	nohup $SCRIPTS/pomodoro/pomodoro-break.sh > /dev/null 2>&1 &
	nohup $SCRIPTS/sound-random.sh >/dev/null 2>&1 &
  sleep 0.5
  nohup bash -c "zenity --question --text 'Time to take a break' --ok-label='+$PROLONGUE_DURATION min' --cancel-label='OK' && ~/my_scripts/pomodoro/pomodoro-prolongue.sh" >/dev/null 2>&1 &
	exit
fi

# pomodoro running -> do nothing
if $SCRIPTS/pomodoro/pomodoro-is-running.sh; then
	echo -n $STATUS
	# better not to remove these exits, I think
	exit
fi

# break -> do nothing
if $SCRIPTS/pomodoro/pomodoro-is-break.sh; then
	echo -n 🍅 $(cat $CUSTOM_SETUP/pomodoro/pomodoro_break_status | awk -F '\x0d' '{print $NF}' | tr -d $'\x0a')
	exit
fi

# break ended -> do start
# if last state was break
if $SCRIPTS/pomodoro/pomodoro-is-break-ended.sh; then
	echo stopped > $CUSTOM_SETUP/pomodoro/state
	nohup bash -c "zenity --info --text 'Break ended. Press OK to get going!'; $SCRIPTS/pomodoro/pomodoro-start.sh" >/dev/null 2>&1 &
	exit
fi

# stopped -> do start if enabled (maybe)
