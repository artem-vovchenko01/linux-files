function my_os_lib_input_yes_or_no {
  lib log "$1"
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) return 0;;
      No ) return 1;;
    esac
  done
}

function my_os_lib_banner {
	lib log "############################################################"
	lib log "# $1"
	lib log "############################################################"
}
