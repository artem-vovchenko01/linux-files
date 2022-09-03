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

function my_os_lib_log_notice {
	my_os_lib_log_color_echo N "$1"
}

function my_os_lib_log_color_echo {
  msg="$2"
  timestamp="$(date +%H:%M:%S)"
  case $1 in
    E)
      color=$MY_OS_COLOR_ERR
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_ERR
      LEVEL=ERR
      ;;
    I)
      color=$MY_OS_COLOR_INFO
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_INFO
      LEVEL=INFO
      ;;
    C)
      color=$MY_OS_COLOR_CMD
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_CMD
      LEVEL=CMD
      ;;
    W)
      color=$MY_OS_COLOR_WARN
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_WARN
      LEVEL=WARN
      ;;
    N)
      color=$MY_OS_COLOR_NOTICE
      echo "$timestamp > $msg" >> $MY_OS_PATH_LOG_NOTICE
      LEVEL=NOTICE
      ;;
  esac
  echo "$timestamp [$LEVEL] $msg" >> $MY_OS_PATH_LOG_ALL
  echo -e "${color}${timestamp} [$LEVEL] ${msg}${MY_OS_COLOR_NONE}"
}

function my_os_lib_log_banner {
	my_os_lib_log_info "############################################################"
	my_os_lib_log_info "# $1"
	my_os_lib_log_info "############################################################"
}

