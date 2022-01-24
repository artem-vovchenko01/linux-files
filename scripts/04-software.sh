#! /usr/bin/env bash
source 00-common.sh

banner "Running software installation script"

check_interactive
[[ -n $INTERACTIVE ]] && {
    ask "Continue running this script?" || exit 0
}

msg_info "Checking dependencies ..."

command -v pacman || { ask "This script optimized for Arch Linux, but you don't have pacman. Exit?" && return; }

##############################
# FUNCTIONS
##############################

function paru_install {
	msg_info 'Paru is not installed. Installing ...'
	exc 'git clone https://aur.archlinux.org/paru.git'
	exc 'cd paru'
	exc 'makepkg -si'
	exc 'cd ..'
	exc 'rm -rf paru'
}

##############################
# INSTALLING PARU
##############################

msg_info 'Updating repositories'
exc 'sudo pacman -Sy'

msg_info 'Checking if paru is installed'
if ! pacman -Q | grep -q paru; then
	ask 'Do you need paru?' Y 'paru_install'
fi

##############################
# INSTALLING SOFTWARE
##############################

while true; do
	exc 'cp software_list.txt software_list_temp.txt'

	msg_info "Comment lines which you don't need ..."
	exc 'nvim software_list_temp.txt'


	soft=$(cat software_list_temp.txt | grep -v '#' | tr '\n' ' ')

	msg_info "Installing selected software ($soft)"
	if pacman -Q | grep -q paru; then
		exc_int "paru -S $soft"
	else
		exc_int "sudo pacman -S $soft"
	fi
	if [[ $? -ne 0 ]]; then
		ask 'Try choosing and installing software again?'
		RET=$?
	else
		RET=1
	fi
	ask "Save temp software list? This will override default list!" N
	[[ $? -eq 0 ]] && exc_int "cp -i software_list_temp.txt software_list.txt"
	exc 'rm software_list_temp.txt'
	[[ $RET -eq 1 ]] && break
done

exc "paru -Scc"

exc "sudo usermod -aG docker artem"
exc "sudo pkgfile --update"

