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
	lib dir $MY_OS_PATH_SOFT_LISTS_DIR
	rm $MY_OS_PATH_HELP_FILE 2> /dev/null
	rm $MY_OS_PATH_WHAT_TO_STOW_FILE 2> /dev/null
	rm *.tmp 2> /dev/null
}

function my_os_lib_check_interactive {
    [ $1 = "-i" ] && INTERACTIVE=1
    [ -z $INTERACTIVE ] && lib log "Running script in non-interactive mode. Pass -i flag for interactive execution."
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

	# exc "ls -l $MY_OS_PATH_ENVS | sed '1d' | cat -n"
	# num_env=$(ls $MY_OS_PATH_ENVS | wc -l)
	# ask_value "Which environment to setup? (1 to $num_env) Press Enter to skip. Press q to quit from program"
	# [[ $VALUE == "q" ]] && msg_warn "Exiting" && exit 0
	# [[ -n $VALUE ]] && {
	#   exc "source $MY_OS_PATH_ENVS/$(ls $MY_OS_PATH_ENVS | sed -n ${VALUE}p)"
	#   continue
	# }
done

