function my_os_lib_log_err {
	my_os_lib_log_color_echo E "$1"
}

function my_os_lib_log_info {
	my_os_lib_log_color_echo I "$1"
}

function my_os_lib_log_cmd {
	my_os_lib_log_color_echo C "$1"
}

function my_os_lib_log_warn {
	my_os_lib_log_color_echo W "$1"
}

function my_os_lib_log_color_echo {
  msg="$2"
  timestamp="$(date +%H:%M:%S)"
  echo "$msg" >> $MY_OS_PATH_LOG_ALL
  case $1 in
    E)
      color=$MY_OS_COLOR_ERR
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_ERR
      ;;
    I)
      color=$MY_OS_COLOR_INFO
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_INFO
      ;;
    C)
      color=$MY_OS_COLOR_CMD
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_CMD
      ;;
    W)
      color=$MY_OS_COLOR_WARN
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_WARN
      ;;
  esac
  echo -e "${color}${timestamp} > ${msg}${MY_OS_COLOR_NONE}"
}

function my_os_lib_log_banner {
	my_os_lib_log_info "############################################################"
	my_os_lib_log_info "# $1"
	my_os_lib_log_info "############################################################"
}

