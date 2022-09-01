lib log banner "Starting user setup script (full setup)"

##############################
# CHECK - USER IS NOT ROOT
##############################

[[ $USER == "root" ]] && { lib log err "Running as root discouraged. Exiting"; exit 1; }

##############################
# DEPENDENCIES
##############################

lib log "Checking dependencies ..."

lib pkg install nvim neovim

##############################
# NETOWRK CONFIGURATION
##############################

lib run interactive "nmtui"
lib snippet ping

##############################
# INSTALLING REQUIRED SOFTWARE
##############################


lib os is arch && {
  lib input "Update repositories?" && lib run "sudo pacman -Sy"
  exc_int "install_pkg base-devel"
}

lib os is arch && {
  lib input "Clone powerlevel10k to home directory?" && lib run "git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ~/powerlevel10k"
}

lib os is debian && {
  lib input "Update repositories?" Y && lib run "sudo apt update"
  lib input "Install build-essential?" Y && lib run "install_pkg build-essential"
}

lib os is fedora && {
  lib log "Current contents of /etc/dnf/dnf.conf: "
  lib run "cat /etc/dnf/dnf.conf"
  lib input "Update /etc/dnf/dnf.conf (fastestmirror, max_parallel_downloads, defaultyes settings)" && {
	  grep -q fastestmirror /etc/dnf/dnf.conf || {
	    lib run "echo fastestmirror=True | sudo tee -a /etc/dnf/dnf.conf"
	    lib run "echo max_parallel_downloads=10 | sudo tee -a /etc/dnf/dnf.conf"
	    lib run "echo defaultyes=True | sudo tee -a /etc/dnf/dnf.conf"
      lib log "Now /etc/dnf/dnf.com:"
	    lib run "cat /etc/dnf/dnf.conf"
	  }
	}

  lib input "Update repositories?" Y && lib run "sudo dnf update"
  lib input "Install NetworkManager-tui, neovim and git?" Y && lib run "sudo dnf install -y NetworkManager-tui neovim git"
  lib input "Install Development Tools and Development Libraries pkg groups?" Y && lib run "sudo dnf groupinstall -y 'Development Tools' 'Development Libraries'"
  lib input "Enable rpmfusion - free?" && sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
  lib input "Enable rpmfusion - nonfree?" && sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  lib input "Add AfterMozilla COPR?" && sudo dnf copr enable bgstack15/AfterMozilla
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

lib run "mkdir -p ~/.config/systemd/user/"
lib input "Install custom systemd units?" && lib run "cp $REPO_PATH/custom-systemd-units/* ~/.config/systemd/user/"
lib input "Enable sway battery manager - custom systemd unit?" && lib run "systemctl --user enable --now sway-battery-warn.timer"

##############################
# LINKING ZHISTORY
##############################

[[ -e ~/.zhistory ]] && lib input "~/.zhistory already exists. Overwrite it and symlink to reference one?" && lib run "ln -sf $DESKTOP_BACKUPS_PATH/zsh/.zhistory ~/.zhistory"
[[ ! -e ~/.zhistory ]] && lib run "ln -s $DESKTOP_BACKUPS_PATH/zsh/.zhistory ~/.zhistory"

