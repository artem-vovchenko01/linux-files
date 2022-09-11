lib log "Working on custom systemd units ..."
lib input "Install custom systemd units?" && lib run "cp $MY_OS_PATH_REPO/custom-systemd-units/* ~/.config/systemd/user/"
lib input "Enable sway battery manager - custom systemd unit?" && lib run "systemctl --user enable --now sway-battery-warn.timer"
