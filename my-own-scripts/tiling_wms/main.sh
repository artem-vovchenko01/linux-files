#! /bin/env bash

function turn_on_display {
  dispaly=$1
  mode=$2
  scale=$3
  wlr-randr --output $dispaly --on --mode $mode --scale $scale
}

function turn_off_display {
  dispaly=$1
  wlr-randr --output $dispaly --off
}

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Main menu"
TITLE="Choose what do you want to do:"
MENU="Choose one of the following options:"

function main_menu {
  OPTIONS=(1 "Change wallpaper"
           2 "Configure displays"
           3 "Suspend PC")
  CHOICE=$(dialog --clear \
                  --backtitle "$BACKTITLE" \
                  --title "$TITLE" \
                  --menu "$MENU" \
                  $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" \
                  2>&1 >/dev/tty)
  clear
  case $CHOICE in
          1)
              /home/artem/.my-own-scripts/tiling_wms/sway/wallpaper_picker.sh
              ;;
          2)
              display_menu
              ;;
          3)
              systemctl suspend
              ;;
  esac
}

function display_menu {
  OPTIONS=(1 "Turn on HDMI-A-1"
           2 "Turn on eDP-1"
           3 "Turn off HDMI-A-1"
           4 "Turn off eDP-1"
           5 "Turn on both")
  CHOICE=$(dialog --clear \
                  --backtitle "$BACKTITLE" \
                  --title "$TITLE" \
                  --menu "$MENU" \
                  $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${OPTIONS[@]}" \
                  2>&1 >/dev/tty)
  clear
  case $CHOICE in
          1)
              turn_on_display HDMI-A-1 2560x1440@74.968002Hz 1.2
              ;;
          2)
              turn_on_display eDP-1 1920x1080@60Hz 1
              ;;
          3)
              turn_off_display HDMI-A-1
              ;;
          4)
              turn_off_display eDP-1
              ;;
          5)
              turn_on_display HDMI-A-1 2560x1440@74.968002Hz 1.2
              turn_on_display eDP-1 1920x1080@60Hz 1
              ;;
  esac
}

main_menu
