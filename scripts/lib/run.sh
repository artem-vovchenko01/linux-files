function my_os_lib_run_int {
    # $1 - command
    # $2 - if nonzero, act non-interactively when $INTERACTIVE not set
    if lib settings is-on interactive; then
        lib input "Run $1?"
        lib check-success && lib run "$1" || lib log warn "You declined to run $1"
    else
        lib run "$1"
    fi
}

function my_os_lib_run_default {
	lib log cmd "$1"
  temp_file=$(mktemp)
  eval "$1" 2> $temp_file
	local ERR=$?
	[[ $ERR -eq 0 ]] || { 
      lib log err "Command \"$1\" failed. Code: $ERR"
        [[ $(cat $temp_file | wc -l) -gt 0 ]] && {
          while IFS= read -r line; do
            lib log err "$line"
          done < $temp_file
        }
        rm $temp_file
        my_os_lib_run_if_error_menu "$1"
    }
    return 0
}

function my_os_lib_run_if_error_menu {
  while true; do
      lib settings is-off interactive && lib log warn "Script is running in non-interactive mode. Ignoring the error and continuing" && break
      lib warn "Select what to do about it:"
      lib input choice 'Rerun the command "'"$1"'"' "Start new bash session for troubleshooting" "Show help, if available" "Execute arbitrary command" "Ignore the error and continue running the script"
      lib input is-chosen 1 && {
        lib log cmd "$1"
        eval "$1"
        local ERR=$?
        [[ $ERR -eq 0 ]] && { lib log 'Now, command "'"$1"'" finished successfully!'; break; } || lib log err "Command \"$1\" failed again. Code: $ERR"
      }
      lib input is-chosen 2 && lib run "bash"
      lib input is-chosen 3 && my_os_lib_show_help
      lib input is-chosen 4 && my_os_lib_run_exc_one_command
      lib input is-chosen 5 && break
    done
}

function my_os_lib_run_ignoreerr {
	lib log cmd "$1"
	eval "$1"
	local ERR=$?
	[[ $ERR -eq 0 ]] || lib log err "Command \"$1\" failed. Code: $ERR. Ignoring"
	return $ERR
}

function my_os_lib_run_exc_one_command {
		echo -ne "${MY_OS_COLOR_INFO}>>> "
		read cmd
		echo -ne "${MY_OS_COLOR_NONE}"
		my_os_lib_run_default "$cmd"
}

