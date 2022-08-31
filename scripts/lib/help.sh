function my_os_lib_show_help {
	if [[ -f $MY_OS_PATH_HELP_FILE ]]; then
		cat $MY_OS_PATH_HELP_FILE
	else
		lib log warn "No help available for the moment."
	fi
}

function my_os_lib_help {
	echo "$1" >> .help.txt
}

