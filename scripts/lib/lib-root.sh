function my_os_lib_prepare {
  lib log "Making some preparations ..."
  trap "my_os_lib_exit_cleanup" 0

  lib run "mkdir -p $MY_OS_PATH_REPO/tempfiles"
  lib run "mkdir -p $MY_OS_PATH_SYSTEM_SCRIPTS"
  lib run "mkdir -p $MY_OS_PATH_GIT"

  lib log "All paths updated accordingly to repo path"

  my_os_lib_check_dependencies

  my_os_lib_check_platform

  lib log banner "Your system identified as: $MY_OS_SYSTEM"
}

function my_os_lib_check_dependencies {
  lib log "Checking dependencies ..."
  my_os_lib_check_single_dep nvim neovim
  my_os_lib_check_single_dep git git
  my_os_lib_check_single_dep stow stow
  my_os_lib_check_single_dep curl curl
  my_os_lib_check_single_dep wget wget
}

function my_os_lib_check_single_dep {
  cmd=$1
  pkg=$2
  lib log "dependencies: checking package $pkg providing command $cmd"
  command -v $cmd &> /dev/null || {
    lib log warn "dependencies: $pkg ($cmd) not found! Trying to install ..."
    lib pkg install $pkg
    command -v $cmd || lib log err "Can't install $pkg. Exiting ..." && exit
  }
}

function my_os_lib_show_err_log {
  cat $MY_OS_PATH_LOG_ERR | grep -q '===' &&
  from_line=$(cat -n $MY_OS_PATH_LOG_ERR | grep '===' | tail -n2 | head -n 1 | tr -d ' ' | cut -d $'\t' -f 1) ||
  from_line=1
  [[ -z "$from_line" ]] && from_line=1
  [[ $from_line -le 0 ]] && from_line=1

  while IFS= read -r msg
  do
    echo -e "${MY_OS_COLOR_ERR}${msg}${MY_OS_COLOR_NONE}"
  done < <(cat $MY_OS_PATH_LOG_ERR | tail -n +$from_line)
}

function my_os_lib_show_warn_log {
  cat $MY_OS_PATH_LOG_WARN | grep -q '===' &&
  from_line=$(cat -n $MY_OS_PATH_LOG_WARN | grep '===' | tail -n2 | head -n 1 | tr -d ' ' | cut -d $'\t' -f 1) ||
  from_line=1
  [[ -z "$from_line" ]] && from_line=1
  [[ $from_line -le 0 ]] && from_line=1

  while IFS= read -r msg
  do
    echo -e "${MY_OS_COLOR_WARN}${msg}${MY_OS_COLOR_NONE}"
  done < <(cat $MY_OS_PATH_LOG_WARN | tail -n +$from_line)
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

