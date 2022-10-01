#! /usr/bin/env bash

##################################################
# SCRIPT-SPECIFIC SETUPS
##################################################

function lib_os_script_setup_software {
  lib log notice "Choose the software lists you want to install:"
  lib input multiple-choice $(ls $MY_OS_PATH_SOFT_LISTS_DIR | grep -v flatpak)
  MY_OS_LIB_SELECTED_SOFT_LIST_FILES="$(lib input get-multiple-choice)"
}

function lib_os_script_setup_manage_git_repos {
  lib log notice "Choose repos you want to configure:"
  lib input multiple-choice $(lib git get-all-repos)
  MY_OS_LIB_SELECTED_REPOS=$(lib input get-multiple-choice)
  # archive password
  lib input secret-value "Provide decryption password:"
  password_attempt_1="$(lib input get-value)"
  lib input secret-value "Repeat the password:"
  [[ "$password_attempt_1" -eq "$(lib input get-value)" ]] || { lib log err "Passwords doesn't match!"; exit; }
  lib settings set zip_passwd_decrypt $(lib input get-value)

  lib input secret-value "Provide encryption password:"
  password_attempt_1="$(lib input get-value)"
  lib input secret-value "Repeat the password:"
  [[ "$password_attempt_1" -eq "$(lib input get-value)" ]] || { lib log err "Passwords doesn't match!"; exit; }
  lib settings set zip_passwd_encrypt $(lib input get-value)
}

function lib_os_choose_script_preset {
  lib input interactive "Choose preset script list? " || return
  CHOICES=(
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/base-scripts/00-base-script.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/base-scripts/05-configs.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/base-scripts/06-symlink-dirs.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/environments/sway.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/base-scripts/04-software.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/software/lunarvim.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/system/symlink-binaries.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/base-scripts/10-fonts.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/system/install-custom-systemd-units.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/software/npm.sh
    )
    for script in ${CHOICES[@]}; do
      echo $script
    done
    lib input interactive "Choose this list? " && return


  CHOICES=
  CHOICES=(
      this-is-line-for-bug-fix
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/other/manage-git-repos.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/software/epam-suite.sh
      /home/artem_vovchenko/.my-git-os/linux-files/scripts/additional-scripts/environments/sway-graphical.sh
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
# SOURCE LIBRARIES
##################################################
source $MY_OS_PATH_LIB/lib-root.sh

##################################################
# ENTRY POINT
##################################################

# read sudo password
lib log notice "Enter sudo password, so you won't need to do it again"
lib run "sudo pwd > /dev/null"

# settings
lib input "Run script non-interactively?" && lib settings set-off interactive

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

