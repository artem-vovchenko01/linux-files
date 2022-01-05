#! /usr/bin/env bash
source 00-common.sh

banner "Running config deployment script"

ask "Continue running this script?" || exit 0

##############################
# DEPENDENCIES
##############################

msg_info "Checking dependencies ..."
check_and_install nvim neovim
check_and_install stow

##############################
# STOWING CONFIGS
##############################

STOW_DIR=..
TARGET_DIR=~

##############################
# STOWING
##############################

while true; do
	exc "echo '##### Leave only lines with packages you want to stow' > what_to_stow.txt"
	exc "echo -e '##### Lines starting with # will be ignored\n' >> what_to_stow.txt"
	exc "ls $STOW_DIR | grep -vE 'LICENSE|README|scripts|symlink_dirs' >> what_to_stow.txt"

	msg_info 'Leave only lines with packages you want to stow'
	sleep 2
	exc_int 'nvim what_to_stow.txt'

	FILES_TO_STOW="$(cat what_to_stow.txt | grep -v '#' | tr '\n' ' ')"
	exc_int "stow -d $STOW_DIR -t $TARGET_DIR $FILES_TO_STOW"
	[[ $? -eq 0 ]] && msg_info 'Successfully finished stowing configs' && break
	ask 'Do you want to retry stowing configs?'
	[[ $? -ne 0 ]] && msg_warn 'Stowing configs not finished properly but setup can continue' && break
done

##############################
# UNSTOWING IF NEEDED
##############################

while true; do
	exc "echo '##### Leave only lines with packages you want to UNstow' > what_to_unstow.txt"
	exc "echo -e '##### Lines starting with # will be ignored\n' >> what_to_unstow.txt"
	exc "ls $STOW_DIR | grep -vE 'LICENSE|README|scripts|symlink_dirs' >> what_to_unstow.txt"

	msg_info 'Leave only lines with packages you want to UNstow'
	sleep 2
	exc_int 'nvim what_to_unstow.txt'

	FILES_TO_STOW="$(cat what_to_unstow.txt | grep -v '#' | tr '\n' ' ')"
	exc_int "stow -D -d $STOW_DIR -t $TARGET_DIR $FILES_TO_STOW"
	[[ $? -eq 0 ]] && msg_info 'Successfully finished unstowing configs' && break
	ask 'Do you want to retry UNstowing configs?'
	[[ $? -ne 0 ]] && msg_warn 'Stowing configs not finished properly but setup can continue' && break
done

[[ -e what_to_stow.txt ]] && rm what_to_stow.txt
[[ -e what_to_unstow.txt ]] && rm what_to_unstow.txt

