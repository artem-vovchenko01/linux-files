#!/usr/bin/env bash
CUSTOM_SETUP=~/custom-setup
SOUNDS_PATH=$CUSTOM_SETUP/hyprland/sounds

NEW_SOUND=$(find $SOUNDS_PATH -type f | shuf -n 1)
pw-play --volume 0.4 $NEW_SOUND
