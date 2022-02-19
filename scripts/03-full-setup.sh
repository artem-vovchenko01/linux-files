banner "Starting user setup script (full setup)"

##############################
# CHECK - USER IS NOT ROOT
##############################

[[ $USER == "root" ]] && { msg_err "Running as root discouraged. Exiting"; exit 1; }

##############################
# DEPENDENCIES
##############################

msg_info "Checking dependencies ..."

check_and_install nvim neovim

##############################
# NETOWRK CONFIGURATION
##############################

exc_int "nmtui"
exc_ping

##############################
# INSTALLING REQUIRED SOFTWARE
##############################

grep -q fastestmirror /etc/dnf/dnf.conf || {
	exc "echo fastestmirror=True | sudo tee -a /etc/dnf/dnf.conf"
	exc "echo max_parallel_downloads=10 | sudo tee -a /etc/dnf/dnf.conf"
	exc "echo defaultyes=True | sudo tee -a /etc/dnf/dnf.conf"
}

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
  exc "sudo dnf install -y NetworkManager-tui neovim git"
  exc_int "sudo dnf groupinstall -y 'Development Tools' 'Development Libraries'"
  ask "Enable rpmfusion - free?" && sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
  ask "Enable rpmfusion - nonfree?" N && sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  ask "Add AfterMozilla COPR?" Y && sudo dnf copr enable bgstack15/AfterMozilla
}

true

##############################
# GRUB CONFIGURATION
##############################

# exc_int "less /etc/default/grub"
# exc "echo GRUB_DISABLE_OS_PROBER=false | sudo tee -a /etc/default/grub"
# exc "sudo update-grub"

##############################
# CUSTOM SYSTEMD UNITS
##############################

mkdir -p ~/.config/systemd/user/
cp $REPO_PATH/custom-systemd-units/* ~/.config/systemd/user/
systemctl --user enable --now sway-battery-warn.timer

