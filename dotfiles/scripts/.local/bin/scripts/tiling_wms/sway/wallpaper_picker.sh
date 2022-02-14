# Dependencies:
#   * wofi
#   * swaymsg
#
# Assumptions:
#   * ~/wallpapers exists
#   * sway config exists at ~/.config/sway/config
#   * sway config contains line with HOME/wallpapers substring

WALLPAPER_PATH=~/Wallpapers

background=$(ls $WALLPAPER_PATH | wofi -S dmenu)

sed -Ei "s/^set \\\$default_wallpaper.*/set \\\$default_wallpaper $background/" ~/.config/sway/config

swaymsg reload
notify-send "Wallpaper $background set!"

