function my_os_lib_menu_os_is {
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
   esac
}

function my_os_lib_menu_os_arch {
  case $1 in
    mirrors)
      my_os_lib_os_arch_sudo_mirror
      ;;
  esac
}