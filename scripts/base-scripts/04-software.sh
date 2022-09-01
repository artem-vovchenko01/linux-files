lib log banner "Running software installation script"

lib log "Checking dependencies ..."

lib pkg install nvim neovim

lib log 'Updating repositories...'

lib input "Update repositories?" && {
	lib os is arch && lib run 'sudo pacman -Sy'
	lib os is debian && lib run 'sudo apt update'
	lib os is fedora && lib run 'sudo dnf update'
}

##############################
# FUNCTIONS
##############################

function paru_install {
	lib log 'Paru is not installed. Installing ...'
	lib run 'git clone https://aur.archlinux.org/paru-bin.git'
	lib run 'cd paru-bin'
	lib run 'makepkg -si'
	lib run 'cd ..'
	lib run 'rm -rf paru-bin'
}

##############################
# INSTALLING PARU
##############################

lib os is arch && {
  lib log 'Checking if paru is installed'
  if ! pacman -Q | grep -q paru; then
    lib input 'Do you need paru?' && paru_install
  fi
}

##############################
# INSTALLING SOFTWARE
##############################

function work_on_soft_list {
    local list_file=$1
    local one_by_one=""
    while true; do
        lib run "cp $list_file $list_file.tmp"
        lib log "Working on software list $list_file.tmp ..."
        lib input "Install them with confirmation?" && one_by_one=1
        lib log "Comment lines which you don't need ..."
        lib run "nvim $list_file.tmp"

        local soft=$(cat $list_file.tmp | grep -v '#' | tr '\n' ' ')

        lib log "Verifying existence of packages in the repo"
        local soft_tmp=$soft
        soft=""
        for pkg in $soft_tmp; do
          verify_pkg_exists $pkg && soft="$soft $pkg"
        done

        msg_info "Installing selected software ($soft)"
        for pkg in $soft; do
          if [[ -z $one_by_one ]]; then
              lib run "install_pkg $pkg" || { ask "Try installing $pkg again?" Y && lib run "install_pkg $pkg"; }
          else
              lib run "install_pkg $pkg 1" || { ask "Try installing $pkg again?" Y && lib run "install_pkg $pkg"; }
          fi
        done

        if [[ $? -ne 0 ]]; then
            ask 'Try choosing and installing software again?' Y
            RET=$?
        else
            RET=1
        fi
        ask "Save temp software list? This will override default list!" N
        [[ $? -eq 0 ]] && lib run "cp -i $list_file.tmp $list_file"
        lib run "rm $list_file.tmp"
        [[ $RET -eq 1 ]] && break
    done
}

function work_on_flatpak_list {
    local list_file=$1
    while true; do
        lib run "cp $list_file $list_file.tmp"
        msg_warn "Working on software list $list_file.tmp ..."
        msg_info "Comment lines which you don't need ..."
        lib run "nvim $list_file.tmp"

        local soft=$(cat $list_file.tmp | grep -v '#' | tr '\n' ' ')

        msg_info "Installing selected software ($soft)"
        for pkg in $soft; do
          lib run "sudo flatpak install $pkg"
        done

        if [[ $? -ne 0 ]]; then
            ask 'Try choosing and installing software again?' Y
            RET=$?
        else
            RET=1
        fi
        ask "Save temp software list? This will override default list!" N
        [[ $? -eq 0 ]] && lib run "cp -i $list_file.tmp $list_file"
        lib run "rm $list_file.tmp"
        [[ $RET -eq 1 ]] && break
    done
}

command -v flatpak && ask "Try adding flathub repo?" Y && lib run "sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"

for soft_list_file in $( find $(cd $SOFT_LISTS_DIR; pwd) -type f ); do
    ask "Install packages (with regular pkg manager) from $soft_list_file list?" Y && work_on_soft_list $soft_list_file
done

for soft_list_file in $(find $(cd $SOFT_LISTS_DIR/flatpak; pwd) -type f ); do
    ask "Install flatpaks from $soft_list_file list?" Y && work_on_flatpak_list $soft_list_file
done

verify_cmd_exists paru && lib run interactive "paru -Scc"

lib run interactive "sudo usermod -aG docker $USER"
verify_cmd_exists pkgfile && lib run interactive "sudo pkgfile --update"

