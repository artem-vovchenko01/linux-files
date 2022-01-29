banner "Running neovim installation script"

##############################
# DEPENDENCIES
##############################

check_and_install nvim neovim
check_and_install curl
check_and_install fzf

##############################
# INSTALLING VIM-PLUG
##############################

[[ -e ~/.config/nvim/init.vim ]] || { ask "You don't have ~/.config/nvim/init.vim. You might want to rerun config setup script! Run it?" Y "source $CONFIG_SCRIPT"; }

if [[ ! -e "$XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim" ]]; then
    exc "sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'"
    msg_warn "Now, run :PlugInstall in neovim. Launching nvim ..."
    sleep 2
    exc "nvim"

   else
       msg_warn "Path to vim-plug exist. Skipping vim-plug install"
fi

