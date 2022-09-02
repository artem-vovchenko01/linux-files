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

lib settings default

lib input secret-value "Please, provide password for encrypting and decrypting archives. It won't be shown to the screen and will be stored only in-memory"
lib settings set zip_passwd $(lib input get-value)

lib input "Run script non-interactively?" && lib settings set-off interactive

while true; do
  lib script-picker
  lib input "Finish the program?" && break
done

