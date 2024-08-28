#!/usr/bin/env bash
WALL_PATH=/home/artem/Hyprland/Wallpapers
NEW_WALL=$(find $WALL_PATH -type f | shuf -n 1)
hyprctl hyprpaper preload "$NEW_WALL"
hyprctl hyprpaper wallpaper "HDMI-A-1,$NEW_WALL"
notify-send -i $NEW_WALL "$(basename $NEW_WALL)"
