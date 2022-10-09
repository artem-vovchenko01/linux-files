#! /usr/bin/env bash

##################################################
# SCRIPT-SPECIFIC SETUPS
##################################################


function lib_os_choose_script_preset {
  lib input interactive "Choose preset script list? " || return
  CHOICES=(
      $HOME/.my-git-os/linux-files/scripts/base-scripts/00-base-script.sh
      $HOME/.my-git-os/linux-files/scripts/base-scripts/05-configs.sh
      $HOME/.my-git-os/linux-files/scripts/base-scripts/06-symlink-dirs.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/environments/sway.sh
      $HOME/.my-git-os/linux-files/scripts/base-scripts/04-software.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/software/lunarvim.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/system/symlink-binaries.sh
      $HOME/.my-git-os/linux-files/scripts/base-scripts/10-fonts.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/system/install-custom-systemd-units.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/software/npm.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/other/manage-git-repos.sh
    )
    for script in ${CHOICES[@]}; do
      echo $script
    done
    lib input interactive "Choose this list? " && return


  CHOICES=
  CHOICES=(
      this-is-line-for-bug-fix
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/other/manage-git-repos.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/software/epam-suite.sh
      $HOME/.my-git-os/linux-files/scripts/additional-scripts/environments/sway-graphical.sh
    )
    for script in ${CHOICES[@]}; do
      echo $script
    done

    lib input interactive "Choose this list? " || lib log notice "Not choosing anything" && CHOICES=
}

##################################################
# GLOBAL VARIABLES
##################################################
# these variables are duplicated in lib-root.sh
MY_OS_PATH_BASE=~/.my-git-os
MY_OS_PATH_REPO=$MY_OS_PATH_BASE/linux-files
MY_OS_PATH_SCRIPTS=$MY_OS_PATH_REPO/scripts
MY_OS_PATH_LIB=$MY_OS_PATH_SCRIPTS/lib

##################################################
# INITIAL SETUP
##################################################

[[ -e $MY_OS_PATH_BASE ]] || { 
  echo "It's probably your first time running this script. Doing set up steps ..."
  mkdir -p $MY_OS_PATH_BASE
  cd $MY_OS_PATH_BASE
  git clone https://www.github.com/artem-vovchenko01/linux-files
  cd -
  echo "Initial setup steps completed!"
}

##################################################
# SOURCE LIBRARIES AND BASE SCRIPT
##################################################
source $MY_OS_PATH_LIB/lib-root.sh
source $MY_OS_PATH_SCRIPTS/base-scripts/00-base-script.sh

##################################################
# ENTRYPOINT
##################################################

# settings
lib input "Run script non-interactively?" && { 
  lib settings set-off interactive
  # read sudo password
  lib log notice "Enter sudo password, so you won't need to do it again"
  lib run "sudo pwd > /dev/null"
}

# script choosing and script-specific setups
lib settings is-off interactive && {
  lib_os_choose_script_preset

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

