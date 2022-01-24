#! /usr/bin/env bash
source 00-common.sh

banner "Running misc script"

ask "Continue running this script?" || exit 0

##############################
# CHECK DEPENDENCIES
##############################

msg_info "Checking dependencies ..."
check_and_install nvim neovim

NO_PACMAN=0
command -v pacman || {
    msg_warn "Pacman not installed! Some parts of script won't be available"
    NO_PACMAN=1
}

##############################
# CONFIGURING PACMAN
##############################

[[ $NO_PACMAN -eq 0 ]] && {
    msg_warn "Go to /etc/pacman.conf and insert after [options] the following:"
    echo
    echo "Color"
    echo "CheckSpace"
    echo "ParallelDownloads = 8"
    echo
    echo "[manjaro-sway]"
    echo "SigLevel = PackageRequired"
    echo 'Server = https://packages.manjaro-sway.download/$arch'
    echo
    ask "Copied? Ready to go?" Y
    exc_int "sudo nvim /etc/pacman.conf"
}

##############################
# SYMLINKING SOME BINARIES
##############################

exc "sudo ln -s /bin/nvim /bin/vi"
exc "sudo ln -s /bin/nvim /bin/vim"

# use dash

##############################
# USE FAST DASH AS SH DEFAULT
##############################

check_and_install dash

exc "sudo ln -sf /bin/dash /bin/sh"

