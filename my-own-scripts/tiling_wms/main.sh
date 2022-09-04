#! /bin/env bash

source ~/.my-git-os/linux-files/scripts/lib/lib-root.sh

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

function main_menu {
  while true; do
     local choices=(
        "Change wallpaper"
        "Configure displays"
        "Suspend PC"
        "Choose network connection"
        "Mount device"
        "Unmount device"
        "Adjust brightness"
        "Exit"
     )
     lib input choice "${choices[@]}"
     lib input is-chosen 1 && /home/artem/.my-own-scripts/tiling_wms/sway/wallpaper_picker.sh
     lib input is-chosen 2 && display_menu
     lib input is-chosen 3 && systemctl suspend
     lib input is-chosen 4 && nmtui
     lib input is-chosen 5 && mount_menu
     lib input is-chosen 6 && umount_menu
     lib input is-chosen 7 && adjust_brightness
   done
}

function adjust_brightness {
  while true; do
    lib input key-choice "k" "Increase brightness" "j" "Decrease brightness"
    lib input is-key-stop-iteration && break
    lib input is-key "k" && lib run "brightnessctl set +10%"
    lib input is-key "j" && lib run "brightnessctl set 10%-"
  done
}

function mount_menu {
  lsblk
  devices=$(cat /proc/partitions | awk '{ print $4 }' | tail -n +3 | grep -v nvme | grep -v zram | grep -v dm-0)
  lib log notice "Choose device you want to mount: "
  lib input choice $devices
  choice=$(lib input get-choice)
  lib run "sudo mkdir -p /mnt/$choice"
  lib run "sudo mount -o rw,gid=artem,uid=artem /dev/$choice /mnt/$choice" 
}

function umount_menu {
  lsblk
  devices=$(cat /proc/partitions | awk '{ print $4 }' | tail -n +3 | grep -v nvme | grep -v zram | grep -v dm-0)
  devices=$(mount | awk '{ print $3 }' | grep /mnt)
  lib log notice "Choose device you want to un-mount: "
  lib input choice $devices
  choice=$(lib input get-choice)
  lib run "sudo umount $choice"
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
