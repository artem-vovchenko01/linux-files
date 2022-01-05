#! /usr/bin/env bash
source ../00-common.sh

msg_info "Starting installation"

ask "Make sure you use your personal account!"
[[ $? -eq 0 ]] || exit 1

exc_int "sudo pacman -S sddm"
exc_int "sudo pacman -S noto-fonts"
exc_int "sudo systemctl enable sddm"
exc_int "sudo pacman -S plasma-meta"
exc_int "sudo pacman -S kde-applications-meta"
exc_int "reboot"

