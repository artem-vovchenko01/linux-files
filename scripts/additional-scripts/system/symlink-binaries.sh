##############################
# SYMLINKING SOME BINARIES
##############################

[[ -e /home/artem_vovchenko/.local/bin/lvim ]] && {
  lib run "sudo ln -sf /home/artem_vovchenko/.local/bin/lvim /bin/vi"
  lib run "sudo ln -sf /home/artem_vovchenko/.local/bin/lvim /bin/vim"
} || [[ -e /bin/nvim ]] && {
  lib run "sudo ln -sf /bin/nvim /bin/vi"
  lib run "sudo ln -sf /bin/nvim /bin/vim"
}

