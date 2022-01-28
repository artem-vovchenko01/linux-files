#! /usr/bin/env bash
source ../00-common.sh

msg_info "Starting installation"

ask "Make sure you use your personal account!"
[[ $? -eq 0 ]] || exit 1

source ~/.zprofile
exc "qt5ct"
exc "lxappearance"

