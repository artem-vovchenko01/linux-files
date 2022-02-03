# Dependencies:
#   * wofi
#   * swaymsg
#
# Assumptions:
#   * ~/wallpapers exists
#   * sway config exists at ~/.config/sway/config
#   * sway config contains line with HOME/wallpapers substring

background=$(ls ~/wallpapers/ | wofi -S dmenu)

sed -Ei "/HOME\/wallpapers/ s/(wallpapers\/)[^[:space:]]+/\1$background/" ~/.config/sway/config

swaymsg reload

