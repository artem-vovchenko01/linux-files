#! /usr/bin/env bash
source 00-common.sh

banner "Starting user setup script (full setup)"

##############################
# CHECK - USER IS NOT ROOT
##############################

[[ $USER == "root" ]] && { msg_err "Running as root discouraged. Exiting"; exit 1; }

# pacman-mirrors -f

NO_PACMAN=0

##############################
# DEPENDENCIES
##############################

msg_info "Checking dependencies ..."

check_and_install nvim neovim

command -v pacman || {
    msg_warn "Pacman is not installed! Some parts of script won't be available"
    NO_PACMAN=1
}

##############################
# NETOWRK CONFIGURATION
##############################

exc "nmtui"
exc_ping

##############################
# PACMAN-SPECIFIC INSTRUCTIONS
##############################

[[ $NO_PACMAN -eq 0 ]] && {
    msg_info "Updating repositories"
    exc 'sudo pacman -Sy'

    msg_info "Making sure NeoVim, git, base-devel are installed"
    exc 'sudo pacman -S neovim git base-devel'
}

##############################
# GRUB CONFIGURATION
##############################

# exc_int "less /etc/default/grub"
# exc "echo GRUB_DISABLE_OS_PROBER=false | sudo tee -a /etc/default/grub"
# exc "sudo update-grub"

##############################
# SOURCING CONSEQUENT SCRIPTS
##############################

source $SOFTWARE_SCRIPT
source 03_1-user-setup.sh

exc "ls -l ./environments"
NUM_ENV=$(ls ./environments | wc -l)
ask_value "Which environment to setup? (select 1 to $NUM_ENV)"
source ./environments/$(ls ./environments | sed -n "${VALUE}p")

