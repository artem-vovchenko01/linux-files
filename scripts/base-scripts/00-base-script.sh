# Installing basic software and dependencies

my_os_lib_check_single_dep nvim neovim
my_os_lib_check_single_dep git git
my_os_lib_check_single_dep stow stow
my_os_lib_check_single_dep curl curl
my_os_lib_check_single_dep wget wget

# Check networking

# lib run interactive "nmtui"
# lib log "Checking network connectivity ..."
# lib snippet ping

lib run "wget -q --spider http://google.com"

##############################
# INSTALLING REQUIRED SOFTWARE
##############################

lib log "Doing some OS-dependent chores ..."
lib os is arch && {
  lib log "Setting up parallel downloads for pacman ..."
  sudo sed -i '/#ParallelDownloads/ s/^.*$/ParallelDownloads = 10/' /etc/pacman.conf
  lib input "Update repositories?" && lib run "sudo pacman -Sy"
  lib pkg install base-devel
}

lib os is arch && {
  # lib input "Clone powerlevel10k to home directory?" && lib run "git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ~/powerlevel10k"
  echo
}

lib os is debian && {
  lib input "Update repositories?" && lib run "sudo apt update"
  lib input "Install build-essential?" && lib run "lib pkg install build-essential"
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

##############################
# LINKING ZHISTORY
##############################

[[ -e $(lib path software-backups)/zsh/.zhistory ]] && {
  [[ -e ~/.zhistory ]] && lib input "~/.zhistory already exists. Overwrite it and symlink to reference one?" && lib run "ln -sf $(lib path software-backups)/zsh/.zhistory ~/.zhistory"
  [[ ! -e ~/.zhistory ]] && lib run "ln -s $(lib path software-backups)/zsh/.zhistory ~/.zhistory"
}

