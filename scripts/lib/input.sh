function my_os_lib_input_yes_or_no {
  lib log notice "$1"
  lib settings is-off interactive && {
    lib log notice "Running in non-interactive mode. Choosing YES as intended by the script"
    return 0
  }
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) return 0;;
      No ) return 1;;
    esac
  done
}

function my_os_lib_input_is_key_stop_iteration {
  case $my_os_lib_input_char in
    q)
      return 0
      ;;
  esac
  return 1
}

function my_os_lib_input_key_choice {
   while [[ ! -z $1 ]]; do 
     echo "$1) $2"
     shift 2
   done
   echo "q) End working with this menu"

   read -n 1 my_os_lib_input_char
}

function my_os_lib_input_is_key {
  case $my_os_lib_input_char in
    $1)
      return 0
      ;;
  esac
  return 1
}

function my_os_lib_input_no_or_yes {
  lib log notice "$1"
  lib settings is-off interactive && {
    lib log notice "Running in non-interactive mode. Choosing NO as intended by the script"
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
  local SAVE_COLUMNS=$COLUMNS
  COLUMNS=12
  select CHOICE in "$@"; do
    return $REPLY
  done
  COLUMNS=$SAVE_COLUMNS
}

function my_os_lib_input_get_choice {
  echo "$CHOICE"
}

function my_os_lib_input_is_chosen {
  [[ $REPLY -eq $1 ]] && return 0 || return 1
}

function my_os_lib_input_get_value {
  echo "$VALUE"
}

function my_os_lib_input_ask_value {
	lib log notice "$1"
	echo -ne "${MY_OS_COLOR_NOTICE}>>> "
	read VALUE
	echo -e "${MY_OS_COLOR_NONE}"
}

function my_os_lib_input_ask_secret_value {
	lib log notice "$1"
	echo -ne "${MY_OS_COLOR_NOTICE}>>> "
	read -s VALUE
	echo -e "${MY_OS_COLOR_NONE}"
}

