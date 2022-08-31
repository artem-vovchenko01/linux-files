function my_os_lib_settings_is_on {
  case $1 in
  interactive)
    [[ $MY_OS_SETTINGS_INTERACTIVE -eq 1 ]] && return 0 || return 1
    ;;
  esac
}

function my_os_lib_settings_set_on {
  case $1 in
    interactive)
      MY_OS_SETTINGS_INTERACTIVE=1
      ;;
  esac
}

function my_os_lib_settings_set_off {
  case $1 in
    interactive)
      MY_OS_SETTINGS_INTERACTIVE=0
      ;;
  esac
}

function my_os_lib_settings_default {
  my_os_lib_settings_set_on interactive
}

