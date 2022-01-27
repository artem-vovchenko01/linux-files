NC='\033[0m' # No Color
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
BLUE_COLOR='\033[0;34m'
YELLOW_COLOR='\033[0;33m'

WARN_CLR="$YELLOW_COLOR"
ERR_CLR="$RED_COLOR"
CMD_CLR="$BLUE_COLOR"
INFO_CLR="$GREEN_COLOR"

HELP_FILE=.help.txt

SOFTWARE_SCRIPT=04-software.sh
CONFIG_SCRIPT=05-configs.sh
SYMLINK_SCRIPT=06-symlink-dirs.sh
ZSH_SCRIPT=07-zsh.sh
NVIM_SCRIPT=08-nvim.sh
MISC_SCRIPT=09-misc.sh

REPO_PATH=/mnt/data/Desktop/linux-files

function configure_repo_path {
	echo "Main repo with configs:"
	echo "$REPO_PATH"
	ask "Change repo path? " && {
	    ask_value "Enter custom path: "
	    REPO_PATH=$VALUE
	    echo "New path:"
	    echo "$REPO_PATH"
	    sleep 5
	}
}

function exc_ping {
    exc "ping archlinux.org -c 3"
}

function root_mirror {
    reflector --protocol https --latest 5 --country Ukraine --sort rate --save /etc/pacman.d/mirrorlist
}

function sudo_mirror {
    sudo reflector --protocol https --latest 5 --country Ukraine --sort rate --save /etc/pacman.d/mirrorlist
}

function check_interactive {
    [ $1 = "-i" ] && INTERACTIVE=1
    [ -z $INTERACTIVE ] && msg_info "Running script in non-interactive mode. Pass -i flag for interactive execution."
}

function banner {
	msg_warn "############################################################"
	msg_warn "# $1"
	msg_warn "############################################################"
}

function color_echo {
	local NC='\033[0m' # No Color
	echo -e "${2}>>> ${1}${NC}"
}

function check_and_install {
	local CMD="$1"
	[[ ! -z $2 ]] && local PKG="$2" || local PKG="$1"
	command -v $CMD || {
	    ask "$CMD not found. Install $PKG to provide it?"
	    [[ $? -eq 0 ]] && install_cmd "$PKG"
	}
}

function install_cmd {
	local PKG="$1"
	command -v apt && sudo apt install "$PKG"
	command -v pacman && sudo pacman -S "$PKG"
	command -v dnf && sudo dnf in "$PKG"
}

function msg_err {
	color_echo "$1" $ERR_CLR
}

function msg_info {
	color_echo "$1" $INFO_CLR
}

function msg_cmd {
	color_echo "$1" $CMD_CLR
}

function msg_warn {
	color_echo "$1" $WARN_CLR
}

function ask_value {
	msg_warn "$1"
	echo -ne "${WARN_CLR}>>> "
	read VALUE
	echo -ne "${NC}"
}

function ask {
	# params
	# $1 - question
	# $2 - default value
	# $3 - positive action (optional)
	# $4 - alternative action (optional)
	# Returns 0 if user chose Yes and 1 if chose No
	if [[ -z $2 ]]; then
		local DEFAULT_VAL='Y'
	else
		local DEFAULT_VAL=$2
	fi
	local KEY=$DEFAULT_VAL
	local RET=0
	msg_info "$1"
	echo -ne "${WARN_CLR}>>> Your choice: "
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
			echo -ne "${WARN_CLR}>>> "
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

function exc_int {
    # $1 - command
    # $2 - if nonzero, act non-interactively when $INTERACTIVE not set
    if [[ -z $2 ]]; then
        ask "${INFO_CLR}Run ${WARN_CLR}$1 ${INFO_CLR}?${NC}"
        [[ $? -eq 0 ]] && exc "$1"
    else
        exc "$1"
    fi
}

function exc {
	msg_cmd "$1"
	eval "$1"
	local ERR=$?
	[[ $ERR -eq 0 ]] || { msg_err "Command \"$1\" failed. Code: $ERR" && ask "Drop to terminal?" && msg_warn "Dropping to terminal" && exc_usr_with_help; }
    return $ERR
}

function help {
	echo "$1" >> .help.txt
}

function show_help {
	if [[ -f $HELP_FILE ]]; then
		cat $HELP_FILE
	else
		msg_warn "No help available for the moment."
	fi
}

function exc_usr_with_help {
	msg_warn "You're in manual command sequence entering mode. Here's help:"
	show_help
	while true; do
		echo -ne "${INFO_CLR}>>> "
		read cmd
		echo -ne "${NC}"
		exc "$cmd"
		ask "Show help?" N "show_help"
		ask "Want to enter some more commands?"
		[[ $? -eq 1 ]] && break
	done

	[[ -f $HELP_FILE ]] && rm $HELP_FILE
}

