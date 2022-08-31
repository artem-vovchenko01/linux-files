function my_os_lib_pkg_check_and_install {
	local cmd=$1
	[[ ! -z $2 ]] && local pkg="$2" || local pkg="$1"
	my_os_lib_pkg_verify_cmd_exists $cmd || {
	    lib input "$cmd not found. Install $pkg to provide it?" Y
	    [[ $? -eq 0 ]] && my_os_lib_pkg_install_pkg "$pkg"
	}
}

function my_os_lib_pkg_verify_cmd_exists {
  command -v $1 > /dev/null
}

function my_os_lib_pkg_verify_pkg_exists {
  local pkg=$1
  lib os is arch && my_os_lib_pkg_verify_cmd_exists paru && paru -Si $pkg > /dev/null 2>&1 && return 0
  lib os is arch && pacman -Si $pkg > /dev/null 2>&1 && return 0
  lib os is arch && pacman -Sg $pkg > /dev/null 2>&1 && return 0
  lib os is debian && apt info $pkg > /dev/null 2>&1 && return 0
  lib os is fedora && dnf info $pkg > /dev/null 2>&1 && return 0
  lib log "Package $pkg not found!"
  return 1
}

function my_os_lib_verify_pkg_installed {
	lib os is arch && pacman -Qi $1 > /dev/null 2>&1 && return
	lib os is debian && dpkg -l $1 > /dev/null 2>&1 && return 
	lib os is fedora && rpm -qa | grep -q $1 && return
}

function my_os_lib_pkg_install {
  local pkg=$1
  local confirm=$2
  my_os_lib_pkg_verify_pkg_installed $pkg && { lib log "Package $pkg is already installed, skipping"; return 0; }
  my_os_lib_pkg_verify_pkg_exists $pkg || return 1
  if [[ -z $confirm ]]; then
	  my_os_lib_pkg_verify_cmd_exists pacman && ( pacman -Si $pkg > /dev/null 2>&1 || pacman -Sg $pkg > /dev/null 2>&1 ) && lib run ignoreerr "sudo pacman -S --noconfirm $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists paru && lib run ignoreerr "paru -S --noconfirm $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists apt && lib run ignoreerr "sudo apt install -y $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists dnf && lib run ignoreerr "sudo dnf install -y $pkg" && return 0
  else
    my_os_lib_pkg_verify_cmd_exists pacman_ignoreerr && lib run "sudo pacman -S $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists paru_ignoreerr && lib run "paru -S $pkg"
    my_os_lib_pkg_verify_cmd_exists apt_ignoreerr && lib run "sudo apt install $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists dnf_ignoreerr && lib run "sudo dnf install $pkg" && return 0
  fi
  [[ ! $? -eq 0 ]] && {
	  if [[ -z $confirm ]]; then
		  lib log "Installation of $pkg with no confirmation not succeeded. Trying with confirmation ..."
		  my_os_lib_pkg_install $1 1
	  else
		  lib log "Installing $pkg failed! " && return 1
	  fi
  }
}

