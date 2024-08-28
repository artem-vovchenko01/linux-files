#!/usr/bin/env bash
CUSTOM_SETUP=~/custom-setup

WALL_PATH=$CUSTOM_SETUP/hyprland/wallpapers

CONF=~/.config/wofi/config-wallpapers
NEW_WALL=$(ls $WALL_PATH | xargs -n1 -I {} echo img:$WALL_PATH/{}:text:{} | wofi -c $CONF --dmenu)
[[ $? -ne 0 ]] && exit
NEW_WALL_PATH=$WALL_PATH/$(echo $NEW_WALL | cut -d: -f4)
if [ -f $NEW_WALL_PATH ]; then
	hyprctl hyprpaper preload "$NEW_WALL_PATH"
	hyprctl hyprpaper wallpaper "HDMI-A-1,$NEW_WALL_PATH"
	notify-send -i $NEW_WALL_PATH "$NEW_WALL"
else
	notify-send "Wallpaper $NEW_WALL_PATH not found"
fi
