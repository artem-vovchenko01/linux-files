# lunarvim

[[ -e $HOME/.local/bin/lvim ]] && {
  lib input interactive "Lunarvim is already installed. Uninstall it?" && \
    lib run "bash ~/.local/share/lunarvim/lvim/utils/installer/uninstall.sh"
}

lib log "Installing lunarvim ..."
script_path=$MY_OS_PATH_TEMPFILES/lunarvim_install.sh
curl -o $script_path -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh
chmod +x $script_path
lib run "$script_path -y"

