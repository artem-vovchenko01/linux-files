#! /bin/env bash

source ~/.my-git-os/linux-files/scripts/lib/lib-root.sh

function main_menu {
  while true; do
     local choices=(
        "Change wallpaper"
        "Configure displays"
        "Suspend PC"
        "Choose network connection"
        "Work with block devices"
        "Adjust brightness"
	"EPAM"
        "Exit"
     )
     lib input choice "${choices[@]}"
     lib input is-chosen 1 && ~/.my-own-scripts/tiling_wms/sway/wallpaper_picker.sh && continue
     lib input is-chosen 2 && display_menu && continue
     lib input is-chosen 3 && systemctl suspend && continue
     lib input is-chosen 4 && nmtui && continue
     lib input is-chosen 5 && mounting_devices_menu && continue
     lib input is-chosen 6 && adjust_brightness && continue
     lib input is-chosen 7 && epam_menu && continue
     lib input is-chosen 8 && break
   done
}

function epam_menu {
  while true; do
     local choices=(
        "Restart GlobalProtect service"
        "Back to main menu"
     )
     lib input choice "${choices[@]}"
     lib input is-chosen 1 && {
	    lib run "sudo systemctl restart gpd.service"
     	    lib run "systemctl status gpd.service"
     } && continue
     lib input is-chosen 2 && break
   done
}

function mounting_devices_menu {
  while true; do
     local choices=(
        "Block mount"
        "Block unmount"
        "MTP mount"
        "MTP unmount"
        "List block devices"
        "Show drives"
        "Back to main menu"
     )
     lib input choice "${choices[@]}"
     lib input is-chosen 1 && mount_menu && continue
     lib input is-chosen 2 && umount_menu && continue
     lib input is-chosen 3 && mtp_mount && continue
     lib input is-chosen 4 && mtp_unmount && continue
     lib input is-chosen 5 && lsblk && continue
     lib input is-chosen 6 && sudo fdisk -l && continue
     lib input is-chosen 7 && break
   done
}

function mtp_mount {
  lib log "Listing all devices: "
  gio mount -l
  available=$(gio mount -li | grep activation_root | cut -d= -f2)
  available_for_mount=""
  mounted=$(gio mount -l | grep Mount | grep -oE 'mtp://.*')
  for device in $available; do
    echo $mounted | grep -q $device || available_for_mount="$available_for_mount $device"
  done
  lib log "Choose MTP device to mount: "
  lib input choice $available_for_mount Cancel
  chosen=$(lib input get-choice)
  [[ $chosen == "Cancel" ]] && lib log "Cancelled" || {
    lib log "Trying to mount $chosen ..."
    lib run "gio mount $chosen"
  }
}

function mtp_unmount {
  lib log "Listing all devices: "
  gio mount -l
  available=$(gio mount -l | grep Mount | grep -oE 'mtp://.*')
  lib log "Choose MTP device to unmount: "
  lib input choice $available Cancel
  chosen=$(lib input get-choice)
  [[ $chosen == "Cancel" ]] && lib log "Cancelled" || {
    lib log "Trying to unmount $chosen ..."
    lib run "gio mount -u $chosen"
  }
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
  lib run "sudo mount -o rw,gid=$(whoami),uid=$(whoami) /dev/$choice /mnt/$choice" 
  lib log "Device /dev/$choice is mounted on /mnt/$choice"
  lsblk
}

function umount_menu {
  lsblk
  devices=$(cat /proc/partitions | awk '{ print $4 }' | tail -n +3 | grep -v zram | grep -v dm-0)
  devices=$(mount | awk '{ print $3 }' | grep /mnt)
  lib log notice "Choose device you want to un-mount: "
  lib input choice $devices
  choice=$(lib input get-choice)
  lib log "Launching terminal for monitoring of dirty pages, which could impact unmounting time: "
  foot bash -c 'watch grep -e Dirty -e Writeback: /proc/meminfo' &> /dev/null &
  foot_pid=$(jobs -l | grep foot | awk '{ print $2 }')
  lib run "sudo umount $choice"
  lib log "Device /dev/$choice is unmounted from /mnt/$choice"
  lsblk
  kill $foot_pid
}

function display_menu {
  while true; do
    local choices=(
      "Configure and turn on display"
      "Turn off display"
      "Back to main menu"
    )
    lib input choice "${choices[@]}"
    lib input is-chosen 1 && lib system configure-displays && continue
    lib input is-chosen 2 && lib system turnoff-displays && continue
    lib input is-chosen 3 && break
  done
}

main_menu
