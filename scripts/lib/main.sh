#! /usr/bin/env bash

##################################################
# GLOBAL VARIABLES
##################################################
MY_OS_PATH_BASE=~/.my-git-os
MY_OS_PATH_REPO=$MY_OS_PATH_BASE/linux-files
MY_OS_PATH_SCRIPTS=$MY_OS_PATH_REPO/scripts
MY_OS_PATH_LIB=$MY_OS_PATH_SCRIPTS/lib
source $MY_OS_PATH_LIB/lib-root.sh

##################################################
# FUNCTIONS
##################################################


function my_os_lib_check_platform {
  cat /etc/os-release | grep -iq debian && MY_OS_SYSTEM=DEBIAN
  cat /etc/os-release | grep -iq arch && MY_OS_SYSTEM=ARCH
  cat /etc/os-release | grep -iq fedora && MY_OS_SYSTEM=FEDORA
}

function my_os_lib_prepare {
  trap "exit_cleanup" 0

  my_os_lib_setup_repo_paths

  mkdir -p $MY_OS_PATH_REPO/tempfiles
  mkdir -p $MY_OS_PATH_SYSTEM_SCRIPTS

  lib log "All paths updated accordingly to repo path"

  my_os_lib_check_platform

  banner "Your system identified as: $MY_OS_SYSTEM"
}

function my_os_lib_exit_cleanup {
	lib log "Script finished. Cleaning up ..."
	lib dir $SOFT_LISTS_DIR
	rm $HELP_FILE 2> /dev/null
	rm $WHAT_TO_STOW_FILE 2> /dev/null
	rm *.tmp 2> /dev/null
}

function my_os_lib_verify_cmd_exists {
  command -v $1 > /dev/null
}

function my_os_lib_setup_repo_paths {
  # DESKTOP_FILES_PATH=/mnt/data/Desktop
  DESKTOP_BACKUPS_PATH=$DESKTOP_FILES_PATH/Software-backups

  MY_OS_PATH_BASE_SCRIPTS=$MY_OS_PATH_REPO/scripts
  # ENVS_PATH=$MY_OS_PATH_REPO/scripts/environments
  MY_OS_PATH_ADDITIONAL_SCRIPTS=$MY_OS_PATH_REPO/scripts/additional-scripts
  ENVS_PATH=$MY_OS_PATH_ADDITIONAL_SCRIPTS/environments
  SYMLINK_DIRS_PATH=$MY_OS_PATH_REPO/symlink-dirs
  DOTFILES_PATH=$MY_OS_PATH_REPO/dotfiles
  TEMPFILES_PATH=$MY_OS_PATH_REPO/tempfiles
  SOFT_LISTS_DIR=$MY_OS_PATH_BASE_SCRIPTS/software-lists

  HELP_FILE=$TEMPFILES_PATH/help-file.txt
  WHAT_TO_STOW_FILE=$TEMPFILES_PATH/what-to-stow.txt

  ARCH_FROM_SCRATCH_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/01-arch-from-scratch.sh
  AFTER_CHROOT_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/02-after-chroot.sh
  SOFTWARE_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/04-software.sh
  CONFIG_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/05-configs.sh
  SYMLINK_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/06-symlink-dirs.sh
  ZSH_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/07-zsh.sh
  NVIM_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/08-nvim.sh
  MISC_SCRIPT=$MY_OS_PATH_BASE_SCRIPTS/09-misc.sh
}


function my_os_lib_root_mirror {
    reflector --protocol https --latest 5 --country Ukraine --sort rate --save /etc/pacman.d/mirrorlist
}

function my_os_lib_sudo_mirror {
    sudo reflector --protocol https --latest 5 --country Ukraine --sort rate --save /etc/pacman.d/mirrorlist
}

function my_os_lib_check_interactive {
    [ $1 = "-i" ] && INTERACTIVE=1
    [ -z $INTERACTIVE ] && lib log "Running script in non-interactive mode. Pass -i flag for interactive execution."
}


function my_os_lib_color_echo {
	echo -e "${2}>>> ${1}${MY_OS_COLOR_NONE}"
}


function my_os_lib_msg_err {
	color_echo "$1" $MY_OS_COLOR_ERR
}

function my_os_lib_msg_info {
	color_echo "$1" $MY_OS_COLOR_INFO
}

function my_os_lib_msg_cmd {
	color_echo "$1" $MY_OS_COLOR_CMD
}

function my_os_lib_msg_warn {
	color_echo "$1" $MY_OS_COLOR_WARN
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


function my_os_lib_help {
	echo "$1" >> .help.txt
}

function my_os_lib_show_help {
	if [[ -f $HELP_FILE ]]; then
		cat $HELP_FILE
	else
		lib log warn "No help available for the moment."
	fi
}


##################################################
# ENTRY POINT
##################################################

prepare

while true; do
  echo *
	# Default scripts
	script_list="$(find $MY_OS_PATH_BASE_SCRIPTS -maxdepth 1 -type f | grep -v 00 | grep -v stow.txt | grep -v 'root-script' | rev | cut -d '/' -f 1 | rev | sort)"
	echo "$script_list" | cat -n
	num_scripts=$(echo "$script_list" | wc -l)
	ask_value "Which script to run? (1 to $num_scripts). Press Enter to skip to environments list. Press q to quit from program"
	[[ $VALUE == "q" ]] && msg_warn "Exiting" && exit 0
	[[ -n $VALUE ]] && {
	  chosen_script=$MY_OS_PATH_BASE_SCRIPTS/$(echo "$script_list" | sed -n ${VALUE}p)
	  msg_info "Running $chosen_script ..."
	  exc "source $chosen_script"
	  [[ $chosen_script == $ARCH_FROM_SCRATCH_SCRIPT ]] && exit
	  [[ $chosen_script == $AFTER_CHROOT_SCRIPT ]] && exit
	  continue
	}

	# Additional scripts

  msg_info "Select script directory"
  select script_dir in $(ls $MY_OS_PATH_ADDITIONAL_SCRIPTS); do
    select script_name in $(ls $MY_OS_PATH_ADDITIONAL_SCRIPTS/$script_dir); do
        script_path=$MY_OS_PATH_ADDITIONAL_SCRIPTS/$script_dir/$script_name
        break
    done
    break
  done

  msg_info "Executing chosen script ($script_path) ..."
  source $script_path

	# exc "ls -l $ENVS_PATH | sed '1d' | cat -n"
	# num_env=$(ls $ENVS_PATH | wc -l)
	# ask_value "Which environment to setup? (1 to $num_env) Press Enter to skip. Press q to quit from program"
	# [[ $VALUE == "q" ]] && msg_warn "Exiting" && exit 0
	# [[ -n $VALUE ]] && {
	#   exc "source $ENVS_PATH/$(ls $ENVS_PATH | sed -n ${VALUE}p)"
	#   continue
	# }
done

