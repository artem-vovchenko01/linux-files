function my_os_lib_pkg_verify_cmd_exists {
  command -v $1 &> /dev/null
}

function my_os_lib_pkg_verify_pkg_exists {
  local pkg=$1
  lib os is arch && my_os_lib_pkg_verify_cmd_exists paru && paru -Si $pkg &> /dev/null && return 0
  lib os is arch && pacman -Si $pkg &> /dev/null && return 0
  lib os is arch && pacman -Sg $pkg &> /dev/null && return 0
  lib os is debian && apt info $pkg &> /dev/null && return 0
  lib os is fedora && dnf info $pkg &> /dev/null && return 0
  lib log warn "Package $pkg not found!"
  return 1
}

function my_os_lib_verify_pkg_installed {
	lib os is arch && pacman -Qi $1 &> /dev/null && return 0
	lib os is debian && dpkg -l $1 &> /dev/null && return 0
	lib os is fedora && rpm -qa | grep -q $1 && return 0
  lib log warn "Package $1 is not installed!"
  return 1
}

function my_os_lib_pkg_install {
  local pkg=$1
  local noconfirm=$2
  my_os_lib_pkg_verify_pkg_installed $pkg && { lib log "Package $pkg is already installed, skipping"; return 0; }
  my_os_lib_pkg_verify_pkg_exists $pkg || return 1
  [[ $noconfirm -eq "Y" ]] || lib settings is-off interactive && {
	  my_os_lib_pkg_verify_cmd_exists pacman && ( pacman -Si $pkg &> /dev/null || pacman -Sg $pkg &> /dev/null ) && 
      lib run "sudo pacman -S --noconfirm $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists paru && lib run "paru -S --noconfirm $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists apt && lib run "sudo apt install -y $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists dnf && lib run "sudo dnf install -y $pkg" && return 0
  } || {
    my_os_lib_pkg_verify_cmd_exists pacman && lib run "sudo pacman -S $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists paru && lib run "paru -S $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists apt && lib run "sudo apt install $pkg" && return 0
    my_os_lib_pkg_verify_cmd_exists dnf && lib run "sudo dnf install $pkg" && return 0
  }
}
