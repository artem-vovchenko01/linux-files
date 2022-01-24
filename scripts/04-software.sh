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

work_on_soft_list {
    LIST_FILE=$1
    ONE_BY_ONE=""
    while true; do
        exc "cp $LIST_FILE $LIST_FILE.tmp"
        msg_warn "Working on software list $LIST_FILE ..."
        ask "Install packages from $LIST_FILE one by one?" && ONE_BY_ONE=1
        msg_info "Comment lines which you don't need ..."
        exc "nvim $LIST_FILE.tmp"

        soft=$(cat $LIST_FILE.tmp | grep -v '#' | tr '\n' ' ')

        msg_info "Installing selected software ($soft)"
        if pacman -Q | grep -q paru; then
            if [[ -z $ONE_BYONE ]]; then
                exc_int "paru -S $soft"
            else
                for pkg in $soft; do
                    exc "paru -S $pkg"
                done
            fi
        else
            if [[ -z $ONE_BYONE ]]; then
                exc_int "sudo pacman -S $soft"
            else
                for pkg in $soft; do
                    exc "sudo pacman -S $pkg"
                done
            fi
        fi
        if [[ $? -ne 0 ]]; then
            ask 'Try choosing and installing software again?'
            RET=$?
        else
            RET=1
        fi
        ask "Save temp software list? This will override default list!" N
        [[ $? -eq 0 ]] && exc_int "cp -i $LIST_FILE.tmp $LIST_FILE"
        exc 'rm software_list_temp.txt'
        [[ $RET -eq 1 ]] && break
    done
}

SOFT_LISTS_DIR=software_lists

for soft_list_file in $(ls $SOFT_LISTS_DIR); do
    work_on_soft_list $SOFT_LISTS_DIR/soft_list_file
done

exc "paru -Scc"

exc "sudo usermod -aG docker artem"
exc "sudo pkgfile --update"

