#!/usr/bin/env bash
set -euo pipefail

if [ -d "$HOME/custom-setup/hyprland/wallpapers" ]; then
    WALL_PATH="$HOME/custom-setup/hyprland/wallpapers"
elif [ -d "$HOME/linux-files/wallpapers" ]; then
    WALL_PATH="$HOME/linux-files/wallpapers"
else
    notify-send "Wallpaper directory not found"
    exit 1
fi

NEW_WALL="$(find "$WALL_PATH" -maxdepth 1 -type f | shuf -n 1)"
[ -z "$NEW_WALL" ] && exit 1

readarray -t MONITORS < <(hyprctl monitors | awk '/^Monitor / { print $2 }')
[ "${#MONITORS[@]}" -eq 0 ] && exit 1

for MONITOR in "${MONITORS[@]}"; do
    hyprctl hyprpaper wallpaper "$MONITOR,$NEW_WALL,cover" >/dev/null
done

notify-send -i "$NEW_WALL" "$(basename "$NEW_WALL")"
