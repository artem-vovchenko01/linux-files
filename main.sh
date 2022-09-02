#! /usr/bin/env bash

##################################################
# GLOBAL VARIABLES
##################################################
MY_OS_PATH_BASE=~/.my-git-os
MY_OS_PATH_REPO=$MY_OS_PATH_BASE/linux-files
MY_OS_PATH_SCRIPTS=$MY_OS_PATH_REPO/scripts
MY_OS_PATH_LIB=$MY_OS_PATH_SCRIPTS/lib

##################################################
# SOURCE LIBRARIES
##################################################
source $MY_OS_PATH_LIB/lib-root.sh

##################################################
# ENTRY POINT
##################################################

function my_os_lib_boot_log_text {
  echo
  echo "======================================"
  echo "Running the script at: $(date)"
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

my_os_lib_init_logs

lib settings default

lib log warn "Enter sudo password, so you won't need to do it again"
lib run "sudo pwd > /dev/null"

lib input secret-value "Please, provide password for encrypting and decrypting archives. It won't be shown to the screen and will be stored only in-memory"
password_attempt_1="$(lib input get-value)"
lib input secret-value "Repeat the password:"
[[ "$password_attempt_1" -eq "$(lib input get-value)" ]] || { lib log err "Passwords doesn't match!"; exit; }
lib settings set zip_passwd $(lib input get-value)

lib input "Run script non-interactively?" && lib settings set-off interactive

lib settings is-off interactive && {
  while true; do
    lib log warn "Choose the software list you want to install:"
    lib input choice $(ls $MY_OS_PATH_SOFT_LISTS_DIR | grep -v flatpak) "Finish"
    soft_list_file="$(lib input get-choice)"
    [[ $soft_list_file == "Finish" ]] && break
    MY_OS_LIB_SELECTED_SOFT_LIST_FILES="$soft_list_file ${MY_OS_LIB_SELECTED_SOFT_LIST_FILES}"
  done
}

while true; do
  lib script-picker
  lib input "Finish the program?" && break
done

