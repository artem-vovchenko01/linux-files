#! /usr/bin/env bash

##################################################
# GLOBAL VARIABLES
##################################################

REPO_PATH=/mnt/data/Desktop/linux-files

# Colors

NC='\033[0m' # No Color
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
BLUE_COLOR='\033[0;34m'
YELLOW_COLOR='\033[0;33m'

WARN_CLR="$YELLOW_COLOR"
ERR_CLR="$RED_COLOR"
CMD_CLR="$BLUE_COLOR"
INFO_CLR="$GREEN_COLOR"

##################################################
# FUNCTIONS
##################################################

function exit_cleanup {
	echo "Script finished. Cleaning up ..."
	cd $SOFT_LISTS_DIR
	rm $HELP_FILE 2> /dev/null
	rm $WHAT_TO_STOW_FILE 2> /dev/null
	rm *.tmp 2> /dev/null
}

function verify_cmd_exists {
  command -v $1 > /dev/null
}

function setup_repo_paths {
  SCRIPTS_PATH=$REPO_PATH/scripts
  ENVS_PATH=$REPO_PATH/scripts/environments
  SYMLINK_DIRS_PATH=$REPO_PATH/symlink-dirs
  DOTFILES_PATH=$REPO_PATH/dotfiles
  TEMPFILES_PATH=$REPO_PATH/tempfiles
  SOFT_LISTS_DIR=$SCRIPTS_PATH/software-lists

  HELP_FILE=$TEMPFILES_PATH/help-file.txt
  WHAT_TO_STOW_FILE=$TEMPFILES_PATH/what-to-stow.txt

  ARCH_FROM_SCRATCH_SCRIPT=$SCRIPTS_PATH/01-arch-from-scratch.sh
  AFTER_CHROOT_SCRIPT=$SCRIPTS_PATH/02-after-chroot.sh
  SOFTWARE_SCRIPT=$SCRIPTS_PATH/04-software.sh
  CONFIG_SCRIPT=$SCRIPTS_PATH/05-configs.sh
  SYMLINK_SCRIPT=$SCRIPTS_PATH/06-symlink-dirs.sh
  ZSH_SCRIPT=$SCRIPTS_PATH/07-zsh.sh
  NVIM_SCRIPT=$SCRIPTS_PATH/08-nvim.sh
  MISC_SCRIPT=$SCRIPTS_PATH/09-misc.sh
}

function output_possible_repo_paths {
  echo "${PWD%/*}"
	echo "/root/linux-files"
	echo "/linux-files"
	echo "$HOME/linux-files"
}

function configure_repo_path {
	[[ -e $REPO_PATH ]] && ask "Repo under default path ($REPO_PATH) available. Use it?" && return
	[[ ! -e $REPO_PATH ]] && msg_warn "Repo path by default not available! Later stage scritps might misbehave"
	msg_warn "Main repo with configs by default:"
	msg_warn "$REPO_PATH"
	local paths_num=$(output_possible_repo_paths | wc -l)
	output_possible_repo_paths | cat -n
	ask_value "Choose one of these (1-$paths_num) or press Enter to enter custom path: "
	if [[ -z $VALUE ]]; then
	    ask_value "Enter custom path: "
	    REPO_PATH=$VALUE
	else
	    REPO_PATH=$(output_possible_repo_paths | sed -n "${VALUE}p")
	fi
    	echo "New path:"
    	echo "$REPO_PATH"
    	sleep 1
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
	local cmd=$1
	[[ ! -z $2 ]] && local pkg="$2" || local pkg="$1"
	verify_cmd_exists $cmd || {
	    ask "$cmd not found. Install $pkg to provide it?"
	    [[ $? -eq 0 ]] && install_pkg "$pkg"
	}
}

function verify_pkg_exists {
  local pkg=$1
  [[ $SYSTEM == "ARCH" ]] && verify_cmd_exists paru && paru -Si $pkg > /dev/null 2>&1 && return 0
  [[ $SYSTEM == "ARCH" ]] && pacman -Si $pkg > /dev/null 2>&1 && return 0
  [[ $SYSTEM == "ARCH" ]] && pacman -Sg $pkg > /dev/null 2>&1 && return 0
  [[ $SYSTEM == "DEBIAN" ]] && apt info $pkg > /dev/null 2>&1 && return 0
  [[ $SYSTEM == "FEDORA" ]] && dnf info $pkg > /dev/null 2>&1 && return 0
  msg_err "Package $pkg not found!"
  return 1
}

function verify_pkg_installed {
	[[ $SYSTEM == "ARCH" ]] && pacman -Qi $1 > /dev/null 2>&1 && return
	[[ $SYSTEM == "DEBIAN" ]] && dpkg -l $1 > /dev/null 2>&1 && return 
	[[ $SYSTEM == "FEDORA" ]] && rpm -qa | grep -q $1 && return
}

function install_pkg {
  local pkg=$1
  local confirm=$2
  verify_pkg_installed $pkg && { msg_info "Package $pkg is already installed, skipping"; return 0; }
  verify_pkg_exists $pkg || return 1
  if [[ -z $confirm ]]; then
	  verify_cmd_exists pacman && ( pacman -Si $pkg > /dev/null 2>&1 || pacman -Sg $pkg > /dev/null 2>&1 ) && exc_ignoreerr "sudo pacman -S --noconfirm $pkg" && return 0
    verify_cmd_exists paru && exc_ignoreerr "paru -S --noconfirm $pkg" && return 0
    verify_cmd_exists apt && exc_ignoreerr "sudo apt install -y $pkg" && return 0
    verify_cmd_exists dnf && exc_ignoreerr "sudo dnf install -y $pkg" && return 0
  else
    verify_cmd_exists pacman_ignoreerr && exc "sudo pacman -S $pkg" && return 0
    verify_cmd_exists paru_ignoreerr && exc "paru -S $pkg"
    verify_cmd_exists apt_ignoreerr && exc "sudo apt install $pkg" && return 0
    verify_cmd_exists dnf_ignoreerr && exc "sudo dnf install $pkg" && return 0
  fi
  [[ ! $? -eq 0 ]] && {
	  if [[ -z $confirm ]]; then
		  msg_warn "Installation of $pkg with no confirmation not succeeded. Trying with confirmation ..."
		  install_pkg $1 1
	  else
		  msg_err "Installing $pkg failed! " && return 1
	  fi
  }
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

function exc_ignoreerr {
	msg_cmd "$1"
	eval "$1"
	local ERR=$?
	[[ $ERR -eq 0 ]] || msg_err "Command \"$1\" failed. Code: $ERR. Ignoring"
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

##################################################
# ENTRY POINT
##################################################

trap "exit_cleanup" 0

setup_repo_paths
configure_repo_path
setup_repo_paths
msg_info "All paths updated accordingly to repo path"

cat /etc/os-release | grep -iq debian && SYSTEM=DEBIAN
cat /etc/os-release | grep -iq arch && SYSTEM=ARCH
cat /etc/os-release | grep -iq fedora && SYSTEM=FEDORA

banner "Your system identified as: $SYSTEM"
sleep 1

while true; do
	##### Default scripts
	script_list="$(find $SCRIPTS_PATH -maxdepth 1 -type f | grep -v 00 | grep -v stow.txt | grep -v 'root-script' | rev | cut -d '/' -f 1 | rev | sort)"
	echo "$script_list" | cat -n
	num_scripts=$(echo "$script_list" | wc -l)
	ask_value "Which script to run? (1 to $num_scripts). Press Enter to skip to environments list. Press q to quit from program"
	[[ $VALUE == "q" ]] && msg_warn "Exiting" && exit 0
	[[ -n $VALUE ]] && {
	  chosen_script=$SCRIPTS_PATH/$(echo "$script_list" | sed -n ${VALUE}p)
	  msg_info "Running $chosen_script ..."
	  exc "source $chosen_script"
	  [[ $chosen_script == $ARCH_FROM_SCRATCH_SCRIPT ]] && exit
	  [[ $chosen_script == $AFTER_CHROOT_SCRIPT ]] && exit
	  continue
	}

	#### Environment scripts

	exc "ls -l $ENVS_PATH | cat -n"
	num_env=$(ls $ENVS_PATH | wc -l)
	ask_value "Which environment to setup? (1 to $num_env) Press Enter to skip. Press q to quit from program"
	[[ $VALUE == "q" ]] && msg_warn "Exiting" && exit 0
	[[ -n $VALUE ]] && {
	  exc "source $ENVS_PATH/$(ls $ENVS_PATH | sed -n ${VALUE}p)"
	  continue
	}
done

