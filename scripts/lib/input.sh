function my_os_lib_input_yes_or_no {
  lib log warn "$1"
  lib settings is-off interactive && {
    lib log warn "Running in non-interactive mode. Choosing YES as intended by the script"
    return 0
  }
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) return 0;;
      No ) return 1;;
    esac
  done
}

function my_os_lib_input_no_or_yes {
  lib log warn "$1"
  lib settings is-off interactive && {
    lib log warn "Running in non-interactive mode. Choosing NO as intended by the script"
    return 1
  }
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) return 0;;
      No ) return 1;;
    esac
  done
}

function my_os_lib_input_choice {
  select CHOICE in "$@"; do
    return $REPLY
  done
}

function my_os_lib_input_get_choice {
  echo "$CHOICE"
}

function my_os_lib_input_is_chosen {
  [[ $REPLY -eq $1 ]] && return 0 || return 1
}

function my_os_lib_ask_value {
	lib log warn "$1"
	echo -ne "${MY_OS_COLOR_WARN}>>> "
	read VALUE
	echo -ne "${MY_OS_COLOR_NONE}"
}

