CUSTOM_SETUP_DIR=~/custom-setup

mkdir -p $CUSTOM_SETUP_DIR/hyprland/state

if [[ "$(cat $CUSTOM_SETUP_DIR/hyprland/state/is_user_idle)" -eq "1" ]]; then
  exit 0
else
  exit 1
fi
