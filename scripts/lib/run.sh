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
	eval "$1"
	local ERR=$?
	[[ $ERR -eq 0 ]] || { 
      lib log err "Command \"$1\" failed. Code: $ERR" && 
      lib input "Drop to terminal?" && 
      lib log warn "Dropping to terminal" && 
      my_os_lib_run_exc_usr_with_help
    }
    return $ERR
}

function my_os_lib_run_ignoreerr {
	lib log cmd "$1"
	eval "$1"
	local ERR=$?
	[[ $ERR -eq 0 ]] || lib log err "Command \"$1\" failed. Code: $ERR. Ignoring"
	return $ERR
}

function my_os_lib_run_exc_usr_with_help {
	lib log warn "You're in manual command sequence entering mode. Here's help:"
	my_os_lib_show_help
	while true; do
		echo -ne "${MY_OS_COLOR_INFO}>>> "
		read cmd
		echo -ne "${MY_OS_COLOR_NONE}"
		my_os_lib_run_default "$cmd"
		lib input "Show help?" && my_os_lib_show_help
		lib input "Want to enter some more commands?"
		lib check-success || break
	done

	[[ -f $HELP_FILE ]] && rm $HELP_FILE
}

