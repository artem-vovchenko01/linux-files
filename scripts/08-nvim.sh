#! /usr/bin/env bash
source 00-common.sh

banner "Running neovim installation script"

ask "Continue running this script?" || exit 0

##############################
# DEPENDENCIES
##############################

check_and_install nvim neovim
check_and_install curl

##############################
# INSTALLING VIM-PLUG
##############################

exc "sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'"

[[ -e ~/.config/nvim/init.vim ]] || { ask "You don't have ~/.config/nvim/init.vim. You might want to rerun config setup script! Run it?" Y "source $CONFIG_SCRIPT"; }

msg_warn "Now, run :PlugInstall in neovim. Launching nvim ..."
sleep 2
exc "nvim"

