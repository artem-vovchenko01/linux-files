function my_os_lib_prepare {
  trap "exit_cleanup" 0

  my_os_lib_setup_repo_paths

  mkdir -p $MY_OS_PATH_REPO/tempfiles
  mkdir -p $MY_OS_PATH_SYSTEM_SCRIPTS

  lib log "All paths updated accordingly to repo path"

  my_os_lib_check_platform

  lib log banner "Your system identified as: $MY_OS_SYSTEM"
}

function my_os_lib_exit_cleanup {
	lib log "Script finished. Cleaning up ..."
	lib dir $MY_OS_PATH_SOFT_LISTS_DIR
	rm $MY_OS_PATH_HELP_FILE 2> /dev/null
	rm $MY_OS_PATH_WHAT_TO_STOW_FILE 2> /dev/null
	rm *.tmp 2> /dev/null
}

my_os_lib_prepare

source $MY_OS_PATH_LIB/env.sh
source $MY_OS_PATH_LIB/os.sh
source $MY_OS_PATH_LIB/dir.sh
source $MY_OS_PATH_LIB/git.sh
source $MY_OS_PATH_LIB/log.sh
source $MY_OS_PATH_LIB/pkg.sh
source $MY_OS_PATH_LIB/run.sh
source $MY_OS_PATH_LIB/help.sh
source $MY_OS_PATH_LIB/input.sh
source $MY_OS_PATH_LIB/lib-cli.sh

