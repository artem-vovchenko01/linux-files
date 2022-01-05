#! /usr/bin/env bash
source 00-common.sh

banner "Running zsh installation script"
ask "Continue running this script?" || exit 0

##############################
# RESOLVING DEPENDENCIES
##############################

msg_info "Checking dependencies ..."
check_and_install zsh
check_and_install wget
check_and_install git
check_and_install nvim neovim

##############################
# INSTALLING OH MY ZSH
##############################

exc_int "wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

exc_int "sh install.sh --unattended"
exc_int "rm install.sh"

##############################
# INSTALLING OH MY ZSH PLUGINS
##############################

exc_int "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
exc_int "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
msg_warn "Now, go to .zshrc and paste these plugins:"

echo
echo "plugins=( "
echo "  git"
echo "  zsh-autosuggestions"
echo "  zsh-syntax-highlighting"
echo ")"
echo

msg_warn "Copy lines above and get ready to edit .zshrc"
sleep 2
exc_int "nvim ~/.zshrc"
[[ -e install.sh.1 ]] && rm install.sh.1

##############################
# INSTALLING POWERLEVEL10k theme
##############################

exc_int "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k"
exc_int "echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc"

##############################
# INSTALLING PERSONAL CONFIG
##############################

exc_int "echo 'source .zshrc.part' >> ~/.zshrc"
[[ -e ~/.zshrc.part ]] || { ask "It appears your .zshrc.part config is not deployed! Run config deployment script now?" && source $CONFIG_SCRIPT; }

##############################
# RUN CHSH
##############################

exc_int "chsh $USER -s /bin/zsh"

