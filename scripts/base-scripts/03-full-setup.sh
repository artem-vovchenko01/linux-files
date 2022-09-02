lib log banner "Starting user setup script (full setup)"

##############################
# CHECK - USER IS NOT ROOT
##############################

[[ $USER == "root" ]] && { lib log err "Running as root discouraged. Exiting"; exit 1; }

##############################
# DEPENDENCIES
##############################

lib log "Checking dependencies ..."

lib pkg install neovim

##############################
# NETOWRK CONFIGURATION
##############################

# lib run interactive "nmtui"
lib snippet ping

##############################
# INSTALLING REQUIRED SOFTWARE
##############################

lib os is arch && {
  lib input "Update repositories?" && lib run "sudo pacman -Sy"
  lib pkg install base-devel
}

lib os is arch && {
  # lib input "Clone powerlevel10k to home directory?" && lib run "git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ~/powerlevel10k"
  echo
}

lib os is debian && {
  lib input "Update repositories?" && lib run "sudo apt update"
  lib input "Install build-essential?" && lib run "install_pkg build-essential"
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

  lib input "Update repositories?" && lib run "sudo dnf update"
  lib input "Install NetworkManager-tui, neovim and git?" && lib run "sudo dnf install -y NetworkManager-tui neovim git"
  lib input "Install Development Tools and Development Libraries pkg groups?" && lib run "sudo dnf groupinstall -y 'Development Tools' 'Development Libraries'"
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
lib input "Install custom systemd units?" && lib run "cp $MY_OS_PATH_REPO/custom-systemd-units/* ~/.config/systemd/user/"
lib input no-yes "Enable sway battery manager - custom systemd unit?" && lib run "systemctl --user enable --now sway-battery-warn.timer"

##############################
# WORKING WITH REPOSITORIES
##############################
lib git select browser-profiles
# [[ ! -e "$(lib git get-artifact-path)" ]] && lib git unpack-artifact
# lib git update-artifact
# lib git force-push-artifact

lib git select software-backups
[[ ! -e "$(lib git get-artifact-path)" ]] && lib git unpack-artifact
lib git update-artifact
lib git force-push-artifact

lib git select vimwiki

exit

##############################
# LINKING ZHISTORY
##############################

[[ -e $(lib path software-backups)/zsh/.zhistory ]] && {
  [[ -e ~/.zhistory ]] && lib input "~/.zhistory already exists. Overwrite it and symlink to reference one?" && lib run "ln -sf $(lib path software-backups)/zsh/.zhistory ~/.zhistory"
  [[ ! -e ~/.zhistory ]] && lib run "ln -s $(lib path software-backups)/zsh/.zhistory ~/.zhistory"
}

