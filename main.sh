#! /usr/bin/env bash

##################################################
# GLOBAL VARIABLES
##################################################
# these variables are duplicated in lib-root.sh
MY_OS_PATH_BASE=~/.my-git-os
MY_OS_PATH_REPO=$MY_OS_PATH_BASE/linux-files
MY_OS_PATH_SCRIPTS=$MY_OS_PATH_REPO/scripts
MY_OS_PATH_LIB=$MY_OS_PATH_SCRIPTS/lib

##################################################
# SOURCE LIBRARIES
##################################################
source $MY_OS_PATH_LIB/lib-root.sh

##################################################
# SCRIPT-SPECIFIC SETUPS
##################################################

function lib_os_script_setup_software {
  lib log warn "Choose the software lists you want to install:"
  lib input multiple-choice $(ls $MY_OS_PATH_SOFT_LISTS_DIR | grep -v flatpak)
  MY_OS_LIB_SELECTED_SOFT_LIST_FILES="$(lib input get-multiple-choice)"
}

function lib_os_script_setup_manage_git_repos {
  # archive password
  lib input secret-value "Please, provide password for encrypting and decrypting archives. It won't be shown to the screen and will be stored only in-memory"
  password_attempt_1="$(lib input get-value)"
  lib input secret-value "Repeat the password:"
  [[ "$password_attempt_1" -eq "$(lib input get-value)" ]] || { lib log err "Passwords doesn't match!"; exit; }
  lib settings set zip_passwd $(lib input get-value)
}

##################################################
# ENTRY POINT
##################################################

# read sudo password
lib log warn "Enter sudo password, so you won't need to do it again"
lib run "sudo pwd > /dev/null"

# settings
lib input "Run script non-interactively?" && lib settings set-off interactive

# script choosing and script-specific setups
lib settings is-off interactive && {
  lib script-multi-picker
  CHOSEN_SCRIPTS=$(lib input get-multiple-choice)

  for script in $CHOSEN_SCRIPTS; do
    [[ $script == ~/.my-git-os/linux-files/scripts/base-scripts/04-software.sh ]] && lib_os_script_setup_software
    [[ $script == ~/.my-git-os/linux-files/scripts/additional-scripts/other/manage-git-repos.sh ]] && lib_os_script_setup_manage_git_repos
  done

  for script in $CHOSEN_SCRIPTS; do
    lib log "Sourcing $script"
    source $script
  done

} || {
  while true; do
    lib script-picker
    lib input "Finish the program?" && break
  done
}

