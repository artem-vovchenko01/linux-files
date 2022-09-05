#!/bin/bash 

pid=$(pgrep wf-recorder)

if pgrep -x "wf-recorder" &> /dev/null; then 
  notify-send -i ~/Resources/Icons/stop-record.png "Stopping the recording ..."
  pkill --signal SIGINT wf-recorder
else 
  notify-send -i ~/Resources/Icons/start-record.png "Starting the recording ..."
  wf-recorder -f ~/Resources/VideoRecordings/$(date +'recording_%Y-%m-%d-%H%M%S.mkv')
fi

