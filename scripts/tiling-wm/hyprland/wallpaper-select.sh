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

CONF="$HOME/.config/wofi/config-wallpapers"
MENU_ENTRIES="$(
    find "$WALL_PATH" -maxdepth 1 -type f -printf '%f\n' \
        | sort \
        | while IFS= read -r WALL; do
            # Wofi image escape format: img:/path/to/image:text:label
            printf 'img:%s/%s:text:%s\n' "$WALL_PATH" "$WALL" "$WALL"
        done
)"

SELECTED="$(
    printf '%s\n' "$MENU_ENTRIES" \
        | wofi -c "$CONF" --dmenu --allow-images --parse-search \
            --define dmenu-parse_action=false --define image_size=28
)"
[ -z "${SELECTED:-}" ] && exit 0

# If wofi returns parsed text only, fall back to filename mode.
if [[ "$SELECTED" == img:*:text:* ]]; then
    NEW_WALL_PATH="${SELECTED#img:}"
    NEW_WALL_PATH="${NEW_WALL_PATH%%:text:*}"
    NEW_WALL="${SELECTED##*:text:}"
else
    NEW_WALL="$SELECTED"
    NEW_WALL_PATH="$WALL_PATH/$NEW_WALL"
fi

if [ ! -f "$NEW_WALL_PATH" ]; then
    notify-send "Wallpaper $NEW_WALL_PATH not found"
    exit 1
fi

readarray -t MONITORS < <(hyprctl monitors | awk '/^Monitor / { print $2 }')
[ "${#MONITORS[@]}" -eq 0 ] && exit 1

for MONITOR in "${MONITORS[@]}"; do
    hyprctl hyprpaper wallpaper "$MONITOR,$NEW_WALL_PATH,cover" >/dev/null
done

notify-send -i "$NEW_WALL_PATH" "$(basename "$NEW_WALL_PATH")"
