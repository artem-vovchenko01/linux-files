#! /usr/bin/env bash
source ../00-common.sh

msg_info "Starting installation"

ask "Make sure you use your personal account!"
[[ $? -eq 0 ]] || exit 1

msg_warn "Console greeter - ly"
exc_int "sudo systemctl enable ly"
exc_int "mkdir ~/.config/sway"
exc_int "cp /etc/sway/config ~/.config/sway/"


