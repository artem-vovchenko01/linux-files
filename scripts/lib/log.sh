function my_os_lib_msg_err {
	my_os_lib_log_color_echo "$1" $MY_OS_COLOR_ERR
}

function my_os_lib_msg_info {
	my_os_lib_log_color_echo "$1" $MY_OS_COLOR_INFO
}

function my_os_lib_msg_cmd {
	my_os_lib_log_color_echo "$1" $MY_OS_COLOR_CMD
}

function my_os_lib_msg_warn {
	my_os_lib_log_color_echo "$1" $MY_OS_COLOR_WARN
}

function my_os_lib_log_color_echo {
	echo -e "${2}>>> ${1}${MY_OS_COLOR_NONE}"
}

function my_os_lib_log_banner {
	lib log "############################################################"
	lib log "# $1"
	lib log "############################################################"
}

