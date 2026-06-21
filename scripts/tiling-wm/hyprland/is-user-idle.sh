IDLE_FILE=~/IT/hyprland/is_user_idle

mkdir -p "$(dirname "$IDLE_FILE")"

if [[ "$(cat "$IDLE_FILE")" -eq "1" ]]; then
  exit 0
else
  exit 1
fi
