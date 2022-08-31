function my_os_lib_input_yes_or_no {
  lib log "$1"
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) return 0;;
      No ) return 1;;
    esac
  done
}

function my_os_lib_input_choice {
  select choice in "$@"; do
    return $REPLY
  done
}

function my_os_lib_input_is_chosen {
  [[ $REPLY -eq $1 ]] && return 0 || return 1
}


function my_os_lib_ask_value {
	msg_warn "$1"
	echo -ne "${MY_OS_COLOR_WARN}>>> "
	read VALUE
	echo -ne "${MY_OS_COLOR_NONE}"
}

function my_os_lib_ask {
	# params
	# $1 - question
	# $2 - default value
	# $3 - positive action (optional)
	# $4 - alternative action (optional)
	# Returns 0 if user chose Yes and 1 if chose No
	if [[ -z $2 ]]; then
		local DEFAULT_VAL='N'
	else
		local DEFAULT_VAL=$2
	fi
	local KEY=$DEFAULT_VAL
	local RET=0
	msg_info "$1"
	echo -ne "${MY_OS_COLOR_WARN}>>> Your choice: "
	if [[ $DEFAULT_VAL == 'Y' || $DEFAULT_VAL == 'y' ]]; then
		echo -e "[Y/n]${NC}"
	elif [[ $DEFAULT_VAL == 'N' || $DEFAULT_VAL == 'n' ]]; then
		echo -e "[N/y]${NC}"
	else 
		msg_err "Internal script error" && exit 1
	fi

	local key
	while true; do
		[[ -z $key ]] && {
			echo -ne "${MY_OS_COLOR_WARN}>>> "
			read key
			echo -ne "${NC}"
		}
		if [[ $key == 'Y' || $key == 'y' ]]; then
			[[ -z "$3" ]] || exc "$3"
			break
		elif [[ $key == 'N' || $key == 'n' ]]; then
			[[ -z "$4" ]] || exc "$4"
			RET=1
			break
		elif [[ -z $key ]]; then
			key=$KEY
		else 
			msg_warn "Make a valid choice: [Y y N n]"
			key=""
		fi
	done
	return $RET
}

