function my_os_lib_prepare {
  lib log "Making some preparations ..."
  trap "my_os_lib_exit_cleanup" 0

  lib run "mkdir -p $MY_OS_PATH_REPO/tempfiles"
  lib run "mkdir -p $MY_OS_PATH_SYSTEM_SCRIPTS"
  lib run "mkdir -p $MY_OS_PATH_GIT"

  lib log "All paths updated accordingly to repo path"

  my_os_lib_check_platform

  lib log banner "Your system identified as: $MY_OS_SYSTEM"
}

function my_os_lib_show_err_log {
  while IFS= read -r msg
  do
    echo -e "${MY_OS_COLOR_ERR}${msg}${MY_OS_COLOR_NONE}"
  done < "$MY_OS_PATH_LOG_ERR"
}

function my_os_lib_show_warn_log {
  while IFS= read -r msg
  do
    echo -e "${MY_OS_COLOR_WARN}${msg}${MY_OS_COLOR_NONE}"
  done < "$MY_OS_PATH_LOG_WARN"
}

function my_os_lib_exit_cleanup {
	lib log "Script finished. Cleaning up ..."
	lib dir $MY_OS_PATH_SOFT_LISTS_DIR
	rm $MY_OS_PATH_HELP_FILE 2> /dev/null
	rm $MY_OS_PATH_WHAT_TO_STOW_FILE 2> /dev/null
	rm *.tmp 2> /dev/null
  lib log "Showing all warnings that've occurred:"
  my_os_lib_show_warn_log
  lib log "Showing all errors that've occurred:"
  my_os_lib_show_err_log
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

function my_os_lib_source_libs {
  source $MY_OS_PATH_LIB/lib-cli.sh
  source $MY_OS_PATH_LIB/log.sh
  source $MY_OS_PATH_LIB/env.sh
  for script in $(ls $MY_OS_PATH_LIB | grep -v lib-root.sh); do
    lib log "lib: sourcing $script"
    source $MY_OS_PATH_LIB/$script
  done
}

my_os_lib_source_libs

my_os_lib_prepare

