function my_os_lib_prepare {
  trap "exit_cleanup" 0

  mkdir -p $MY_OS_PATH_REPO/tempfiles
  mkdir -p $MY_OS_PATH_SYSTEM_SCRIPTS

  lib log "All paths updated accordingly to repo path"

  my_os_lib_check_platform

  lib log banner "Your system identified as: $MY_OS_SYSTEM"
}

function my_os_lib_exit_cleanup {
	lib log "Script finished. Cleaning up ..."
	lib dir $MY_OS_PATH_SOFT_LISTS_DIR
	rm $MY_OS_PATH_HELP_FILE 2> /dev/null
	rm $MY_OS_PATH_WHAT_TO_STOW_FILE 2> /dev/null
	rm *.tmp 2> /dev/null
}

function my_os_lib_script_picker {
  lib log "Select script you want to run"
  lib input choice $(ls $MY_OS_PATH_BASE_SCRIPTS) "Choose other script"

  script_name="$(lib input get-choice)"
  if [[ "$script_name" == "Choose other script" ]]; then
    lib log "Select script directory"
    lib input choice $(ls $MY_OS_PATH_ADDITIONAL_SCRIPTS)
    script_dir="$(lib input get-choice)"
    lib log "Select script you want to run"
    lib input choice $(ls $MY_OS_PATH_ADDITIONAL_SCRIPTS/$script_dir)
    script_name="$(lib input get-choice)"
    script_path=$MY_OS_PATH_ADDITIONAL_SCRIPTS/$script_dir/$script_name
    msg_info "Executing chosen script ($script_path) ..."
    source $script_path
  else
    source $MY_OS_PATH_BASE_SCRIPTS/$script_name
  fi
}

source $MY_OS_PATH_LIB/env.sh
source $MY_OS_PATH_LIB/lib-cli.sh
source $MY_OS_PATH_LIB/log.sh
source $MY_OS_PATH_LIB/os.sh
source $MY_OS_PATH_LIB/dir.sh
source $MY_OS_PATH_LIB/git.sh
source $MY_OS_PATH_LIB/pkg.sh
source $MY_OS_PATH_LIB/run.sh
source $MY_OS_PATH_LIB/help.sh
source $MY_OS_PATH_LIB/input.sh

my_os_lib_prepare

