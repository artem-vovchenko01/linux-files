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

while true; do
  lib script-picker
  lib input "Finish the program?" && break
done

