function lib {
  arg_1="$1"
  shift 1
  case $arg_1 in
    git)
      my_os_lib_menu_git "$@"
      ;;
    log)
      my_os_lib_menu_log "$@"
      ;;
    run)
      my_os_lib_menu_run "$@"
      ;;
    dir)
      my_os_lib_menu_dir "$@"
      ;;
    script-picker)
      my_os_lib_script_picker "$@"
      ;;
    snippet)
      my_os_lib_menu_snippets "$@"
      ;;
    pkg)
      my_os_lib_menu_pkg "$@"
      ;;
    input)
      my_os_lib_menu_input "$@"
      ;;
    os)
      my_os_lib_menu_os "$@"
      ;;
    settings)
      my_os_lib_settings_menu "$@"
      ;;
    check-success)
      [[ $? -eq 0 ]] && return 0 || return 1
      ;;
    *)
      lib log "lib command $1 not found!"
      ;;
  esac
}

function my_os_lib_menu_settings {
  arg_1="$1"
  shift 1
  case $arg_1 in
    is-on)
      my_os_lib_settings_is_on "$@"
      ;;
    is-off)
      my_os_lib_settings_is_off "$@"
      ;;
    set-on)
      my_os_lib_settings_set_on "$@"
      ;;
    set-off)
      my_os_lib_settings_set_off "$@"
      ;;
    default)
      my_os_lib_settings_default
      ;;
  esac
}

function my_os_lib_menu_os {
  arg_1="$1"
  shift 1
  case $arg_1 in
    arch)
      my_os_lib_menu_os_arch
      ;;
    is)
      my_os_lib_os_menu_os_is
      ;;
  esac
}

function my_os_lib_menu_input {
  arg_1="$1"
  shift 1
  case $arg_1 in
    yes-no)
      my_os_lib_input_yes_or_no "$@"
      ;;
    value)
      my_os_lib_input_ask_value "$@"
      ;;
    choice)
      my_os_lib_input_choice "$@"
      ;;
    is-chosen)
      my_os_lib_input_is_chosen "$@"
      ;;
    get-choice)
      my_os_lib_input_get_choice "$@"
      ;;
    *)
      my_os_lib_input_yes_or_no "$@"
      ;;
  esac
}

function my_os_lib_menu_pkg {
  arg_1="$1"
  shift 1
  case $arg_1 in
    install)
      my_os_lib_pkg_install $1 DEFAULT
      ;;
    install-confirm)
      my_os_lib_pkg_install $1 N
      ;;
    install-noconfirm)
      my_os_lib_pkg_install $1 Y
      ;;
    verify-cmd)
      my_os_lib_pkg_verify_cmd_exists $1
      ;;
    verify-pkg-exists)
      my_os_lib_pkg_verify_pkg_exists $1
      ;;
    verify-pkg-installed)
      my_os_lib_pkg_verify_pkg_installed $1
      ;;
  esac
}

function my_os_lib_menu_git {
  arg_1="$1"
  shift 1
  case $arg_1 in
    commit)
      my_os_lib_git_commit "$@"
      ;;
    check-updates)
      my_os_lib_git_check_updates
      ;;
  esac
}

function my_os_lib_menu_log {
  arg_1="$1"
  shift 1
  case $arg_1 in
    info)
      my_os_lib_log_info "$@"
      ;;
    warn)
      my_os_lib_log_warn "$@"
      ;;
    err)
      my_os_lib_log_err "$@"
      ;;
    cmd)
      my_os_lib_log_cmd "$@"
      ;;
    banner)
      my_os_lib_log_banner "$@"
      ;;
    *)
      my_os_lib_log_info "$arg_1" "$@"
      ;;
  esac
}

function my_os_lib_menu_dir {
  arg_1="$1"
  shift 1
  case $arg_1 in
    base)
      cd $MY_OS_PATH_BASE
      ;;
    repo)
      cd $MY_OS_PATH_REPO
      ;;
    base-scripts)
      cd $MY_OS_PATH_BASE_SCRIPTS
      ;;
    additional-scripts)
      cd $MY_OS_PATH_ADDITIONAL_SCRIPTS
      ;;
    git)
      cd $MY_OS_GIT
      ;;
    cd)
      cd "$@"
      ;;
    *)
      cd "$@"
      ;;
  esac
}

function my_os_lib_menu_run {
  arg_1="$1"
  shift 1
  case $arg_1 in
    ignoreerr)
      my_os_lib_run_ignoreerr "$@"
      ;;
    interactive)
      my_os_lib_run_int "$@"
      ;;
    *)
      my_os_lib_run_default "$@"
      ;;
  esac
}

function my_os_lib_menu_snippet {
  arg_1="$1"
  shift 1
  case $arg_1 in
    ping)
      my_os_lib_snippet_ping
      ;;
  esac
}
