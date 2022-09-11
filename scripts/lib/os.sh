function my_os_lib_os_menu_os_is {
  case $1 in
    arch)
       [[ $MY_OS_SYSTEM == "ARCH" ]] && return 0 || return 1
       ;;
    fedora)
       [[ $MY_OS_SYSTEM == "FEDORA" ]] && return 0 || return 1
       ;;
    debian)
       [[ $MY_OS_SYSTEM == "DEBIAN" ]] && return 0 || return 1
       ;;
    debian-based)
       [[ $MY_OS_SYSTEM == "DEBIAN" ]] && return 0
       [[ $MY_OS_SYSTEM == "UBUNTU" ]] && return 0
       return 1
       ;;
    ubuntu)
       [[ $MY_OS_SYSTEM == "UBUNTU" ]] && return 0 || return 1
       ;;
   esac
}

function my_os_lib_menu_os_arch {
  case $1 in
    mirrors)
      my_os_lib_os_arch_sudo_mirror
      ;;
  esac
}

function my_os_lib_root_mirror {
    reflector --protocol https --latest 5 --country Ukraine --sort rate --save /etc/pacman.d/mirrorlist
}

function my_os_lib_sudo_mirror {
    sudo reflector --protocol https --latest 5 --country Ukraine --sort rate --save /etc/pacman.d/mirrorlist
}

function my_os_lib_check_platform {
  cat /etc/os-release | grep -iq debian && MY_OS_SYSTEM=DEBIAN
  cat /etc/os-release | grep -iq ubuntu && MY_OS_SYSTEM=UBUNTU
  cat /etc/os-release | grep -iq arch && MY_OS_SYSTEM=ARCH
  cat /etc/os-release | grep -iq fedora && MY_OS_SYSTEM=FEDORA
}
