function my_os_lib_settings_is_on {
  case $1 in
  interactive)
    [[ $MY_OS_SETTINGS_INTERACTIVE -eq 1 ]] && return 0 || return 1
    ;;
  esac
}

function my_os_lib_settings_is_off {
  case $1 in
  interactive)
    [[ $MY_OS_SETTINGS_INTERACTIVE -eq 0 ]] && return 0 || return 1
    ;;
  esac
}

function my_os_lib_settings_set_on {
  case $1 in
    interactive)
      MY_OS_SETTINGS_INTERACTIVE=1
      lib log warn "lib settings: ON $1"
      ;;
  esac
}

function my_os_lib_settings_set_off {
  case $1 in
    interactive)
      MY_OS_SETTINGS_INTERACTIVE=0
      lib log warn "lib settings: OFF $1"
      ;;
  esac
}

function my_os_lib_settings_default {
  lib log warn "lib settings: setting up defaults ..."
  lib settings set-on interactive
}

