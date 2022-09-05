#! /bin/env bash

source ~/.my-git-os/linux-files/scripts/lib/lib-root.sh

function turn_on_display {
  dispaly=$1
  mode=$2
  scale=$3
  wlr-randr --output $dispaly --on --mode $mode --scale $scale
  lib log "Display $dispaly is turned on"
}

function turn_off_display {
  dispaly=$1
  wlr-randr --output $dispaly --off
  lib log "Display $dispaly is turned off"
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
     lib input is-chosen 1 && /home/artem/.my-own-scripts/tiling_wms/sway/wallpaper_picker.sh && continue
     lib input is-chosen 2 && display_menu && continue
     lib input is-chosen 3 && systemctl suspend && continue
     lib input is-chosen 4 && nmtui && continue
     lib input is-chosen 5 && mount_menu && continue
     lib input is-chosen 6 && umount_menu && continue
     lib input is-chosen 7 && adjust_brightness && continue
     lib input is-chosen 8 && exit
   done
}

function adjust_brightness {
  while true; do
    lib input key-choice "k" "Increase brightness" "j" "Decrease brightness"
    lib input is-key-stop-iteration && break
    lib input is-key "k" && lib run "brightnessctl set +10%"
    lib input is-key "j" && lib run "brightnessctl set 10%-"
  done
  lib log "Brightness adjustment is done!"
}

function mount_menu {
  lsblk
  devices=$(cat /proc/partitions | awk '{ print $4 }' | tail -n +3 | grep -v zram | grep -v dm-0)
  lib log notice "Choose device you want to mount: "
  lib input choice $devices
  choice=$(lib input get-choice)
  lib run "sudo mkdir -p /mnt/$choice"
  lib run "sudo mount -o rw,gid=artem,uid=artem /dev/$choice /mnt/$choice" 
  lib log "Device /dev/$choice is mounted on /mnt/$choice"
}

function umount_menu {
  lsblk
  devices=$(cat /proc/partitions | awk '{ print $4 }' | tail -n +3 | grep -v zram | grep -v dm-0)
  devices=$(mount | awk '{ print $3 }' | grep /mnt)
  lib log notice "Choose device you want to un-mount: "
  lib input choice $devices
  choice=$(lib input get-choice)
  lib run "sudo umount $choice"
  lib log "Device /dev/$choice is unmounted from /mnt/$choice"
}

function display_menu {
  local choices=(
    "Turn on HDMI-A-1"
    "Turn on eDP-1"
    "Turn off HDMI-A-1"
    "Turn off eDP-1"
    "Turn on both"
  )
  lib input choice "${choices[@]}"
  lib input is-chosen 1 && turn_on_display HDMI-A-1 2560x1440@74.968002Hz 1
  lib input is-chosen 2 && turn_on_display eDP-1 1920x1080@60Hz 1
  lib input is-chosen 3 && turn_off_display HDMI-A-1
  lib input is-chosen 4 && turn_off_display eDP-1
  lib input is-chosen 5 && {
      turn_on_display HDMI-A-1 2560x1440@74.968002Hz 1
      turn_on_display eDP-1 1920x1080@60Hz 1
  }
  lib log "Display configuration is finished"
}

main_menu
