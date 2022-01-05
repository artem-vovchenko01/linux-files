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

exc_int "nmtui"

##############################
# PACMAN-SPECIFIC INSTRUCTIONS
##############################

[[ $NO_PACMAN -eq 0 ]] && {
    msg_info "Updating repositories"
    exc_int 'sudo pacman -Sy'

    msg_info "Making sure NeoVim, git, base-devel are installed"
    exc_int 'sudo pacman -S neovim git base-devel'
}

##############################
# GRUB CONFIGURATION
##############################

exc_int "less /etc/default/grub"
exc_int "echo GRUB_DISABLE_OS_PROBER=false | sudo tee -a /etc/default/grub"
exc_int "sudo update-grub"

##############################
# SOURCING CONSEQUENT SCRIPTS
##############################

source $SOFTWARE_SCRIPT
source $CONFIG_SCRIPT
source $SYMLINK_SCRIPT
source $ZSH_SCRIPT
source $NVIM_SCRIPT
source $MISC_SCRIPT

