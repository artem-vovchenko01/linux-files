#!/usr/bin/env bash
SOUNDS_PATH=~/IT/Resources/Sounds

NEW_SOUND=$(find $SOUNDS_PATH -type f | shuf -n 1)
pw-play --volume 0.4 $NEW_SOUND
