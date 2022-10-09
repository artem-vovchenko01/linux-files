MY_OS_STOW_DIR=$MY_OS_PATH_DOTFILES
MY_OS_TARGET_DIR=~

lib log banner "Running config deployment script"

##############################
# BACKING UP IF NOT LINKS
##############################

function backup_if_not_link {
  file=$1
  path=$HOME/$1
  [[ -e $path ]] && [[ ! -L $path ]] && {
    lib log warn "$path exists, and is not a link. Backing up"
    lib run "cp -r $path $path.bak && rm $path"
  }
}

backup_if_not_link .bashrc
backup_if_not_link .zshrc
backup_if_not_link .bash_profile
backup_if_not_link .bash_login
backup_if_not_link .zprofile
backup_if_not_link .ssh
backup_if_not_link .gnupg

# Lunarvim
[[ -d ~/.config/lvim ]] && {
  lib log notice "Configuring lunarvim config, not using stow ..."
  backup_if_not_link .config/lvim/config.lua
  lib run "ln -sf $MY_OS_PATH_DOTFILES/lunarvim/.config/lvim/config.lua ~/.config/lvim/config.lua"
}

##############################
# UNSTOWING IF NEEDED
##############################

lib input no-yes "Do you want to UNSTOW some configs?" && {
    lib run "echo '##### Leave only lines with packages you want to UNstow' > $MY_OS_PATH_WHAT_TO_STOW_FILE"
    lib run "echo -e '##### Lines starting with # will be ignored\n' >> $MY_OS_PATH_WHAT_TO_STOW_FILE"
    lib run "ls $MY_OS_STOW_DIR | grep -vE 'LICENSE|lunarvim|README|symlink_dirs' >> $MY_OS_PATH_WHAT_TO_STOW_FILE"

    lib log 'Leave only lines with packages you want to UNstow'
    lib run "nvim $MY_OS_PATH_WHAT_TO_STOW_FILE"

    MY_OS_FILES_TO_STOW="$(cat $MY_OS_PATH_WHAT_TO_STOW_FILE | grep -v '#' | tr '\n' ' ')"
    for file in $MY_OS_FILES_TO_STOW; do
      lib run "stow -D -d $MY_OS_STOW_DIR -t $MY_OS_TARGET_DIR $file"
    done
}

##############################
# STOWING
##############################

lib input "Do you want to stow some configs?" && {
	lib run "echo '##### Leave only lines with packages you want to stow' > $MY_OS_PATH_WHAT_TO_STOW_FILE"
	lib run "echo -e '##### Lines starting with # will be ignored\n' >> $MY_OS_PATH_WHAT_TO_STOW_FILE"
	lib run "ls $MY_OS_STOW_DIR | grep -vE 'LICENSE|lunarvim|README|symlink-dirs' >> $MY_OS_PATH_WHAT_TO_STOW_FILE"

  lib settings is-on interactive && lib run "nvim $MY_OS_PATH_WHAT_TO_STOW_FILE"

  lib settings is-off interactive && lib log warn "Running in non-interactive mode, not prompting to edit what to stow"

	MY_OS_FILES_TO_STOW="$(cat $MY_OS_PATH_WHAT_TO_STOW_FILE | grep -v '#' | tr '\n' ' ')"
    	for file in $MY_OS_FILES_TO_STOW; do
        	lib run "stow -d $MY_OS_STOW_DIR -t $MY_OS_TARGET_DIR $file"
    	done
}

[[ -e $MY_OS_PATH_WHAT_TO_STOW_FILE ]] && rm $MY_OS_PATH_WHAT_TO_STOW_FILE

