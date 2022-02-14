banner "Running software installation script"

msg_info "Checking dependencies ..."

check_and_install nvim neovim

msg_info 'Updating repositories...'

[[ $SYSTEM == "ARCH" ]] && exc 'sudo pacman -Sy'
[[ $SYSTEM == "DEBIAN" ]] && exc 'sudo apt update'
[[ $SYSTEM == "FEDORA" ]] && exc 'sudo dnf update'

##############################
# FUNCTIONS
##############################

function paru_install {
	msg_info 'Paru is not installed. Installing ...'
	exc 'git clone https://aur.archlinux.org/paru-bin.git'
	exc 'cd paru-bin'
	exc 'makepkg -si'
	exc 'cd ..'
	exc 'rm -rf paru-bin'
}

##############################
# INSTALLING PARU
##############################

[[ $SYSTEM == "ARCH" ]] && {
  msg_info 'Checking if paru is installed'
  if ! pacman -Q | grep -q paru; then
    ask 'Do you need paru?' Y 'paru_install'
  fi
}

##############################
# INSTALLING SOFTWARE
##############################

function work_on_soft_list {
    local list_file=$1
    local one_by_one=""
    while true; do
        exc "cp $list_file $list_file.tmp"
        msg_warn "Working on software list $list_file.tmp ..."
        ask "Install them with confirmation?" N && one_by_one=1
        msg_info "Comment lines which you don't need ..."
        exc "nvim $list_file.tmp"

        local soft=$(cat $list_file.tmp | grep -v '#' | tr '\n' ' ')

        msg_info "Verifying existence of packages in the repo"
        local soft_tmp=$soft
        soft=""
        for pkg in $soft_tmp; do
          verify_pkg_exists $pkg && soft="$soft $pkg"
        done

        msg_info "Installing selected software ($soft)"
        for pkg in $soft; do
          if [[ -z $one_by_one ]]; then
              exc "install_pkg $pkg" || { ask "Try installing $pkg again?" && exc "install_pkg $pkg"; }
          else
              exc "install_pkg $pkg 1" || { ask "Try installing $pkg again?" && exc "install_pkg $pkg"; }
          fi
        done

        if [[ $? -ne 0 ]]; then
            ask 'Try choosing and installing software again?'
            RET=$?
        else
            RET=1
        fi
        ask "Save temp software list? This will override default list!" N
        [[ $? -eq 0 ]] && exc "cp -i $list_file.tmp $list_file"
        exc "rm $list_file.tmp"
        [[ $RET -eq 1 ]] && break
    done
}

function work_on_flatpak_list {
    local list_file=$1
    while true; do
        exc "cp $list_file $list_file.tmp"
        msg_warn "Working on software list $list_file.tmp ..."
        msg_info "Comment lines which you don't need ..."
        exc "nvim $list_file.tmp"

        local soft=$(cat $list_file.tmp | grep -v '#' | tr '\n' ' ')

        msg_info "Installing selected software ($soft)"
        for pkg in $soft; do
          exc "flatpak install $pkg"
        done

        if [[ $? -ne 0 ]]; then
            ask 'Try choosing and installing software again?'
            RET=$?
        else
            RET=1
        fi
        ask "Save temp software list? This will override default list!" N
        [[ $? -eq 0 ]] && exc "cp -i $list_file.tmp $list_file"
        exc "rm $list_file.tmp"
        [[ $RET -eq 1 ]] && break
    done
}

for soft_list_file in $( find $(cd $SOFT_LISTS_DIR; pwd) -type f ); do
    ask "Install packages from $soft_list_file list?" Y && work_on_soft_list $soft_list_file
done

for soft_list_file in $(find $(cd $SOFT_LISTS_DIR/flatpak; pwd) -type f ); do
    ask "Install flatpaks from $soft_list_file list?" Y && work_on_flatpak_list $soft_list_file
done

verify_cmd_exists paru && exc_int "paru -Scc"

exc_int "sudo usermod -aG docker $USER"
verify_cmd_exists pkgfile && exc "sudo pkgfile --update"

