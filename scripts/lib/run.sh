function my_os_lib_run_int {
    # $1 - command
    # $2 - if nonzero, act non-interactively when $INTERACTIVE not set
    if [[  ]]; then
        ask "${MY_OS_COLOR_INFO}Run ${MY_OS_COLOR_WARN}$1 ${MY_OS_COLOR_INFO}?${MY_OS_COLOR_NONE}" Y
        [[ $? -eq 0 ]] && exc "$1"
    else
        exc "$1"
    fi
}

function my_os_lib_run_default {
	msg_cmd "$1"
	eval "$1"
	local ERR=$?
	[[ $ERR -eq 0 ]] || { msg_err "Command \"$1\" failed. Code: $ERR" && ask "Drop to terminal?" Y && msg_warn "Dropping to terminal" && exc_usr_with_help; }
    return $ERR
}

function my_os_lib_run_ignoreerr {
	msg_cmd "$1"
	eval "$1"
	local ERR=$?
	[[ $ERR -eq 0 ]] || msg_err "Command \"$1\" failed. Code: $ERR. Ignoring"
	return $ERR
}

