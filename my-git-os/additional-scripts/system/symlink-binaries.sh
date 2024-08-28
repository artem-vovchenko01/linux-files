##############################
# SYMLINKING SOME BINARIES
##############################

[[ -e $HOME/.local/bin/lvim ]] && {
  lib run "sudo ln -sf $HOME/.local/bin/lvim /bin/vi"
  lib run "sudo ln -sf $HOME/.local/bin/lvim /bin/vim"
} || [[ -e /bin/nvim ]] && {
  lib run "sudo ln -sf /bin/nvim /bin/vi"
  lib run "sudo ln -sf /bin/nvim /bin/vim"
}

