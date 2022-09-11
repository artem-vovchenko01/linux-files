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
# ENTRY POINT
##################################################

# read sudo password
lib log warn "Enter sudo password, so you won't need to do it again"
lib run "sudo pwd > /dev/null"

# archive password
lib input secret-value "Please, provide password for encrypting and decrypting archives. It won't be shown to the screen and will be stored only in-memory"
password_attempt_1="$(lib input get-value)"
lib input secret-value "Repeat the password:"
[[ "$password_attempt_1" -eq "$(lib input get-value)" ]] || { lib log err "Passwords doesn't match!"; exit; }
lib settings set zip_passwd $(lib input get-value)

# settings
lib input "Run script non-interactively?" && lib settings set-off interactive

lib settings is-off interactive && {
  lib log warn "Choose the software lists you want to install:"
  lib input multiple-choice $(ls $MY_OS_PATH_SOFT_LISTS_DIR | grep -v flatpak)
  MY_OS_LIB_SELECTED_SOFT_LIST_FILES="$(lib input get-multiple-choice)"
}

while true; do
  lib script-picker
  lib input "Finish the program?" && break
done

