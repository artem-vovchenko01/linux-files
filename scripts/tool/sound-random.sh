#!/usr/bin/env bash
SOUND_PATH=~/custom-setup/Resources/Sounds
NEW_SOUND=$(find $SOUND_PATH -type f | shuf -n 1)
pw-play --volume 0.4 $NEW_SOUND
