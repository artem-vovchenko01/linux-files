MY_OS_PATH_BASE=~/.my-git-os
MY_OS_PATH_REPO=$MY_OS_PATH_BASE/linux-files
MY_OS_PATH_SCRIPTS=$MY_OS_PATH_REPO/scripts
MY_OS_PATH_LIB=$MY_OS_PATH_SCRIPTS/lib

function my_os_lib_prepare {
  lib log "Making some preparations ..."
  trap "my_os_lib_exit_cleanup" 0

  my_os_lib_prepare_dirs_and_files

  lib log "All paths updated accordingly to repo path"

  my_os_lib_check_platform

  # my_os_lib_check_dependencies

  lib log banner "Your system identified as: $MY_OS_SYSTEM"
}

function my_os_lib_prepare_dirs_and_files {
  mkdir -p $MY_OS_PATH_REPO/tempfiles
  mkdir -p ~/.npm-global
  mkdir -p ~/.local/share/fonts
  mkdir -p ~/.config/systemd/user
  mkdir -p $MY_OS_PATH_SYSTEM_SCRIPTS
  mkdir -p $MY_OS_PATH_GIT

  touch $MY_OS_PATH_LOG_ALL
  touch $MY_OS_PATH_LOG_WARN
  touch $MY_OS_PATH_LOG_ERR
  touch $MY_OS_PATH_LOG_NOTICE
  touch $MY_OS_PATH_LOG_INFO
  touch $MY_OS_PATH_LOG_CMD
}

function my_os_lib_check_single_dep {
  cmd=$1
  pkg=$2
  lib log "dependencies: checking package $pkg providing command $cmd"
  command -v $cmd &> /dev/null || {
    lib log warn "dependencies: $pkg ($cmd) not found! Trying to install ..."
    lib pkg install $pkg
    command -v $cmd || { lib log err "Can't install $pkg. Exiting ..." && exit; }
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
  cat $MY_OS_PATH_LOG_ERR | less
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
  cat $MY_OS_PATH_LOG_WARN | less
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
  lib log notice "Select script you want to run"
  lib input choice $(ls $MY_OS_PATH_BASE_SCRIPTS) "Choose other script"

  script_name="$(lib input get-choice)"
  if [[ "$script_name" == "Choose other script" ]]; then
    lib log "Select script directory"
    lib input choice $(ls -F $MY_OS_PATH_ADDITIONAL_SCRIPTS | grep / | tr -d /)
    script_dir="$(lib input get-choice)"
    lib log "Select script you want to run"
    lib input choice $(ls $MY_OS_PATH_ADDITIONAL_SCRIPTS/$script_dir)
    script_name="$(lib input get-choice)"
    script_path=$MY_OS_PATH_ADDITIONAL_SCRIPTS/$script_dir/$script_name
    
    MY_OS_LIB_CHOSEN_SCRIPT_PATH=$script_path
    [[ $1 != "NO_SOURCE" ]] && lib log notice "Executing chosen script ($script_path) ..." && source $script_path
  else
    MY_OS_LIB_CHOSEN_SCRIPT_PATH=$MY_OS_PATH_BASE_SCRIPTS/$script_name
    [[ $1 != "NO_SOURCE" ]] && source $MY_OS_PATH_BASE_SCRIPTS/$script_name
  fi
}

function my_os_lib_script_multi_picker {
  lib log notice "Picking multiple scripts to run"
  while true; do
    lib log notice "Your choices so far:"
    for choice in ${CHOICES[@]}; do
      echo $choice
    done
    lib input choice "Continue choosing" "Finish" "Remove some chosen scripts"
    CHOICE="$(lib input get-choice)"
    [[ "$CHOICE" == "Finish" ]] && break
    [[ "$CHOICE" == "Remove some chosen scripts" ]] && my_os_lib_script_multi_unpicker && continue

    lib script-picker NO_SOURCE
    CHOICES+=( "$MY_OS_LIB_CHOSEN_SCRIPT_PATH" )
  done
}

function my_os_lib_script_multi_unpicker {
  lib log notice "Deselecting multiple scripts"
  while true; do
    lib input choice ${CHOICES[@]} Done
    CHOICE=$(lib input get-choice)
    [[ $CHOICE ==  "Done" ]] && break
    CHOICES=( $(echo ${CHOICES[@]/$CHOICE}) )
  done
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

function my_os_lib_boot_log_text {
  [[ $0 = /* ]] && local real_path=$0 || local real_path=$(realpath $(pwd)/$0)
  echo
  echo "======================================"
  echo "Running the script $real_path at: $(date)"
  echo "======================================"
  echo
}

function my_os_lib_init_logs {
  my_os_lib_boot_log_text >> $MY_OS_PATH_LOG_ERR
  my_os_lib_boot_log_text >> $MY_OS_PATH_LOG_INFO
  my_os_lib_boot_log_text >> $MY_OS_PATH_LOG_WARN
  my_os_lib_boot_log_text >> $MY_OS_PATH_LOG_CMD
  my_os_lib_boot_log_text >> $MY_OS_PATH_LOG_ALL
}

source $MY_OS_PATH_LIB/env.sh

my_os_lib_prepare_dirs_and_files

my_os_lib_source_libs

my_os_lib_prepare

my_os_lib_init_logs

lib settings default

