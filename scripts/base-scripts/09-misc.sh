lib log banner "Running misc script"

##############################
# CONFIGURING PACMAN
##############################

[[ $SYSTEM = "ARCH" ]] && {
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

[[ $SYSTEM == "DEBIAN" ]] && {
    echo "Now you'll edit /etc/apt/sources.list"
    echo "Maybe you want sth minimal, like this for sid (unstable)"
    echo
    echo "deb http://deb.debian.org/debian/ sid main contrib non-free"
    ask "Copied? Ready to go?" Y
    exc_int "sudo apt edit-sources"
}

[[ $SYSTEM == "FEDORA" ]] && {
  ask "Remove pkg vi? You can symlink it to /bin/nvim" Y && exc "sudo dnf remove vi"
  ask "Source the script with gnome shortcuts?" Y && exc "source $CUSTOM_SCRIPTS_PATH/gnome/gnome_shortcut_script.sh"
}


exc_int "rm -r ~/linux-files"

msg_warn "After you setup the OS, UUIDs for blk devices changed. You probably shuold go to each other Os's partition and change their /etc/fstab, particularly, for efi, swap and this OS"

