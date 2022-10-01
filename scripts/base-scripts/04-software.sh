lib log banner "Running software installation script"

lib log 'Updating repositories...'

lib input "Update repositories?" && {
	lib os is arch && lib run 'sudo pacman -Sy'
	lib os is debian && lib run 'sudo apt update'
	lib os is fedora && lib run 'sudo dnf update'
}

##############################
# FUNCTIONS
##############################

function lib_os_paru_install {
	lib log 'Paru is not installed. Installing ...'
	lib run 'git clone https://aur.archlinux.org/paru-bin.git'
	lib run 'cd paru-bin'
	lib run 'makepkg --noconfirm -si'
	lib run 'cd ..'
	lib run 'rm -rf paru-bin'
}

function my_os_lib_work_on_soft_list {
    local list_file=$1
    local one_by_one=""
    lib run "cp $list_file $list_file.tmp"
    lib log "Working on software list $list_file.tmp ..."
    lib input no-yes "Install them with confirmation for each package?" && one_by_one=1
    lib log "Comment lines which you don't need ..."
    lib settings is-on interactive && lib run "nvim $list_file.tmp"

    local soft=$(cat $list_file.tmp | grep -v '#' | tr '\n' ' ')

    lib log "Verifying existence of packages in the repo"
    local soft_tmp=$soft
    soft=""
    for pkg in $soft_tmp; do
      lib pkg verify-pkg-exists $pkg && soft="$soft $pkg"
    done

    lib log "Installing selected software ($soft)"
    for pkg in $soft; do
      if [[ -z $one_by_one ]]; then
        lib pkg install-noconfirm $pkg
      else
        lib pkg install-confirm $pkg
      fi
    done

    lib input no-yes "Save temp software list? This will override default list!" && lib run "cp -i $list_file.tmp $list_file"
    lib run "rm $list_file.tmp"
}

function my_os_lib_work_on_flatpak_list {
    local list_file=$1
    lib run "cp $list_file $list_file.tmp"
    lib log warn "Working on software list $list_file.tmp ..."
    lib log "Comment lines which you don't need ..."
    lib settings is-on interactive && lib run "nvim $list_file.tmp"

    local soft=$(cat $list_file.tmp | grep -v '#' | tr '\n' ' ')

    lib log "Installing selected software ($soft)"
    for pkg in $soft; do
      lib run "sudo flatpak install $pkg"
    done

    lib input no-yes "Save temp software list? This will override default list!" && lib run "cp -i $list_file.tmp $list_file"
    lib run "rm $list_file.tmp"
}

##############################
# INSTALLING PARU
##############################

lib os is arch && {
  if ! lib pkg verify-cmd paru; then
    lib input 'Paru is not installed. Install?' && lib_os_paru_install
  fi
}

##############################
# INSTALLING SOFTWARE
##############################

# Install regular packages

lib settings is-on interactive && {
  while true; do
    lib log warn "Choose the software list you want to work on:"
    lib input choice $(ls $MY_OS_PATH_SOFT_LISTS_DIR | grep -v flatpak) "Finish"
    soft_list_file="$(lib input get-choice)"
    [[ $soft_list_file == "Finish" ]] && break
    my_os_lib_work_on_soft_list $MY_OS_PATH_SOFT_LISTS_DIR/$soft_list_file
  done
} || {
  for soft_list_file in $MY_OS_LIB_SELECTED_SOFT_LIST_FILES; do
    my_os_lib_work_on_soft_list $MY_OS_PATH_SOFT_LISTS_DIR/$soft_list_file
  done
}

# Install flatpaks
lib pkg verify-cmd flatpak || lib input "Flatpak not found. Install it?" && lib pkg install flatpak
lib pkg verify-cmd flatpak && lib input "Install some flatpaks?" && {
  lib input "Try adding flathub repo?" && lib run "sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
  lib settings is-on interactive && {
    while true; do
      lib log warn "Choose the software list you want to work on:"
      lib input choice $(ls $MY_OS_PATH_SOFT_LISTS_DIR/flatpak) "Finish"
      soft_list_file="$(lib input get-choice)"
      [[ $soft_list_file == "Finish" ]] && break
      my_os_lib_work_on_flatpak_list $MY_OS_PATH_SOFT_LISTS_DIR/$soft_list_file
    done
  }
}

# Clear caches
lib pkg verify-cmd paru && {
  lib settings is-on interactive && lib run "paru -Scc" || lib run "paru -Scc --noconfirm"
}

# Docker group
lib input "Add $USER to docker group?" && lib run "sudo usermod -aG docker $USER"

# pkgfile
lib pkg verify-cmd pkgfile && lib run "sudo pkgfile --update"

