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

function my_os_lib_input_interactive {
  lib log notice "$1"
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

function my_os_lib_input_multiple_choice {
  CHOICES=""
  while true; do
    [[ -n $CHOICES ]] && lib log notice "Already chosen: $CHOICES"
    lib log notice "Choose an option. You can Finish (if done) or Reset (to clear choices):"
    lib input choice "$@" Finish Reset
    choice="$(lib input get-choice)"
    [[ $choice == "Finish" ]] && break
    [[ $choice == "Reset" ]] && CHOICES="" && lib log notice "Choices were successfully reset" && continue
    CHOICES="$choice ${CHOICES}"
  done
  lib log notice "Your final choice is: $CHOICES"
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

function my_os_lib_input_choose_line {
  LINES="$1"
  OLDIFS="$IFS"
  IFS=$'\n'

  final_lines=()

  for line in $LINES; do
    final_lines+=( "$line" )
  done
   
  my_os_lib_input_choice "${final_lines[@]}"

  IFS="$OLDIFS"
}

function my_os_lib_input_get_choice {
  echo "$CHOICE"
}

function my_os_lib_input_get_multiple_choice {
  echo "$CHOICES"
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

