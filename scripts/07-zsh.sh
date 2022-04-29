banner "Running zsh installation script"

##############################
# RESOLVING DEPENDENCIES
##############################

msg_info "Checking dependencies ..."
check_and_install zsh
check_and_install git
check_and_install nvim neovim

##############################
# INSTALLING PERSONAL CONFIG
##############################

[[ -e ~/.zshrc ]] || { ask "It appears your .zshrc.part config is not deployed! Run config deployment script now?" Y && source $CONFIG_SCRIPT; }
[[ -e ~/.shrc.part ]] || { ask "It appears your .zshrc.part config is not deployed! Run config deployment script now?" Y && source $CONFIG_SCRIPT; }
ask "Source .shrc.part from ~/.bashrc?" Y && exc "echo 'source ~/.shrc.part' >> ~/.bashrc"

##############################
# RUN CHSH
##############################

exc_int "chsh $USER -s /bin/zsh"

