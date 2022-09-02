function my_os_lib_path_default {
  case "$1" in
    system-scripts)
      echo "$MY_OS_PATH_SYSTEM_SCRIPTS"
      ;;
    base-scripts)
      echo "$MY_OS_PATH_BASE_SCRIPTS"
      ;;
    additional-scripts)
      echo "$MY_OS_PATH_ADDITIONAL_SCRIPTS"
      ;;
    envs)
      echo "$MY_OS_PATH_ENVS"
      ;;
    symlink-dirs)
      echo "$MY_OS_PATH_SYMLINK_DIRS"
      ;;
    dotfiles)
      echo "$MY_OS_PATH_DOTFILES"
      ;;
    tempfiles)
      echo "$MY_OS_PATH_TEMPFILES"
      ;;
    git)
      echo "$MY_OS_PATH_GIT"
      ;;
    software-lists)
      echo "$MY_OS_PATH_SOFT_LISTS_DIR"
      ;;
    help-file)
      echo "$MY_OS_PATH_HELP_FILE"
      ;;
    what-to-stow)
      echo "$MY_OS_PATH_WHAT_TO_STOW_FILE"
      ;;
    browser-profiles)
      echo $MY_OS_GIT_PATH_FIREFOX_PROFILES
      ;;
    software-backups)
      echo $MY_OS_GIT_PATH_SOFTWARE_BACKUPS
      ;;
    software-backups-dir)
      echo $MY_OS_GIT_PATH_SOFTWARE_BACKUPS/$MY_OS_GIT_ARTIFACT_DIR_SOFTWARE_BACKUPS
      ;;
  esac
}

