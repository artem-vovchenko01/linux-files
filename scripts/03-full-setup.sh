banner "Starting user setup script (full setup)"

##############################
# CHECK - USER IS NOT ROOT
##############################

[[ $USER == "root" ]] && { msg_err "Running as root discouraged. Exiting"; exit 1; }

# pacman-mirrors -f

##############################
# DEPENDENCIES
##############################

msg_info "Checking dependencies ..."

check_and_install nvim neovim

##############################
# NETOWRK CONFIGURATION
##############################

exc "nmtui"
exc_ping

##############################
# INSTALLING REQUIRED SOFTWARE
##############################

exc "install_pkg neovim"
exc "install_pkg git"

[[ $SYSTEM == "ARCH" ]] && {
  exc "sudo pacman -Sy"
  exc_int "install_pkg base-devel"
}

[[ $SYSTEM == "DEBIAN" ]] && {
  exc "sudo apt update"
  exc_int "install_pkg build-essential"
}

[[ $SYSTEM == "FEDORA" ]] && {
  exc "sudo dnf update"
  exc_int "sudo dnf groupinstall 'Development Tools' 'Development Libraries'"
}

##############################
# GRUB CONFIGURATION
##############################

# exc_int "less /etc/default/grub"
# exc "echo GRUB_DISABLE_OS_PROBER=false | sudo tee -a /etc/default/grub"
# exc "sudo update-grub"

