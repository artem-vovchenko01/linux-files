STOW_DIR=$DOTFILES_PATH
TARGET_DIR=~

banner "Running config deployment script"

##############################
# DEPENDENCIES
##############################

msg_info "Checking dependencies ..."
check_and_install nvim neovim
check_and_install stow

##############################
# UNSTOWING IF NEEDED
##############################

ask "Do you want to UNSTOW some configs?" && {
        exc "echo '##### Leave only lines with packages you want to UNstow' > $WHAT_TO_STOW_FILE"
        exc "echo -e '##### Lines starting with # will be ignored\n' >> $WHAT_TO_STOW_FILE"
        exc "ls $STOW_DIR | grep -vE 'LICENSE|README|scripts|symlink_dirs' >> $WHAT_TO_STOW_FILE"

        msg_info 'Leave only lines with packages you want to UNstow'
        exc "nvim $WHAT_TO_STOW_FILE"

        FILES_TO_STOW="$(cat $WHAT_TO_STOW_FILE | grep -v '#' | tr '\n' ' ')"
	for file in $FILES_TO_STOW; do
		exc "stow -D -d $STOW_DIR -t $TARGET_DIR $file"
	done
}

##############################
# STOWING
##############################

ask "Do you want to stow some configs?" && {
	exc "echo '##### Leave only lines with packages you want to stow' > $WHAT_TO_STOW_FILE"
	exc "echo -e '##### Lines starting with # will be ignored\n' >> $WHAT_TO_STOW_FILE"
	exc "ls $STOW_DIR | grep -vE 'LICENSE|README|scripts|symlink-dirs' >> $WHAT_TO_STOW_FILE"

    	exc "nvim $WHAT_TO_STOW_FILE"

	FILES_TO_STOW="$(cat $WHAT_TO_STOW_FILE | grep -v '#' | tr '\n' ' ')"
    	for file in $FILES_TO_STOW; do
        	exc "stow -d $STOW_DIR -t $TARGET_DIR $file"
    	done
}

[[ -e $WHAT_TO_STOW_FILE ]] && rm $WHAT_TO_STOW_FILE

