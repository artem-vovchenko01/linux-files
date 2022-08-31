function lib {
  case $1 in
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
  esac
}

function my_os_lib_menu_settings {
  case $1 in
    is-on)
      my_os_lib_settings_set_on "$@"
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
  case $1 in
    arch)
      my_os_lib_menu_os_arch
      ;;
    is)
      my_os_lib_os_is_menu
      ;;
  esac
}


function my_os_lib_menu_input {
  case $1 in
    yes-no)
      my_os_lib_input_yes_or_no "$@"
      ;;
    value)
      my_os_lib_input_ask_value "$@"
      ;;
    *)
      my_os_lib_input_yes_or_no "$@"
      ;;
  esac
}

function my_os_lib_menu_pkg {
  case $1 in
    install)
      my_os_lib_pkg_install_pkg
      ;;
    remove)
      # my_os_lib_verify_pkg_installed
      ;;
    verify-cmd)
      my_os_lib_pkg_verify_cmd_exists
      ;;
    verify-pkg)
      my_os_lib_pkg_verify_pkg_exists
      ;;
  esac
}

function my_os_lib_menu_git {
  case $1 in
    commit)
      my_os_lib_git_commit "$@"
      ;;
    check-updates)
      my_os_lib_git_check_updates
      ;;
  esac
}
function my_os_lib_menu_log {
  case $1 in
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
    *)
      my_os_lib_log_info "$@"
      ;;
  esac
}

function my_os_lib_menu_dir {
  case $1 in
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
  case $1 in
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
  case $1 in
    ping)
      my_os_lib_snippet_ping
      ;;
  esac
}
