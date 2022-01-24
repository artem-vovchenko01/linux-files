#! /usr/bin/env bash
source 00-common.sh

banner "Running zsh installation script"

check_interactive

[[ -n $INTERACTIVE ]] && {
    ask "Continue running this script?" || exit 0
}

##############################
# RESOLVING DEPENDENCIES
##############################

msg_info "Checking dependencies ..."
check_and_install zsh
check_and_install wget
check_and_install git
check_and_install nvim neovim

##############################
# INSTALLING PERSONAL CONFIG
##############################

[[ -e ~/.zshrc ]] || { ask "It appears your .zshrc.part config is not deployed! Run config deployment script now?" && source $CONFIG_SCRIPT; }
[[ -e ~/.zshrc.part ]] || { ask "It appears your .zshrc.part config is not deployed! Run config deployment script now?" && source $CONFIG_SCRIPT; }

##############################
# RUN CHSH
##############################

exc_int "chsh $USER -s /bin/zsh"

