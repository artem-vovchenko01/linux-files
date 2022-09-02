MY_OS_PATH_SYSTEM_SCRIPTS=$MY_OS_PATH_BASE/system-scripts

# Colors

MY_OS_COLOR_NONE='\033[0m'
MY_OS_COLOR_RED='\033[0;31m'
MY_OS_COLOR_GREEN='\033[0;32m'
MY_OS_COLOR_BLUE='\033[0;34m'
MY_OS_COLOR_YELLOW='\033[0;33m'

MY_OS_COLOR_WARN="$MY_OS_COLOR_YELLOW"
MY_OS_COLOR_ERR="$MY_OS_COLOR_RED"
MY_OS_COLOR_CMD="$MY_OS_COLOR_BLUE"
MY_OS_COLOR_INFO="$MY_OS_COLOR_GREEN"

MY_OS_SYSTEM=

MY_OS_PATH_BASE_SCRIPTS=$MY_OS_PATH_SCRIPTS/base-scripts
MY_OS_PATH_ADDITIONAL_SCRIPTS=$MY_OS_PATH_SCRIPTS/additional-scripts
MY_OS_PATH_ENVS=$MY_OS_PATH_ADDITIONAL_SCRIPTS/environments
MY_OS_PATH_SYMLINK_DIRS=$MY_OS_PATH_REPO/symlink-dirs
MY_OS_PATH_DOTFILES=$MY_OS_PATH_REPO/dotfiles
MY_OS_PATH_TEMPFILES=$MY_OS_PATH_REPO/tempfiles
MY_OS_PATH_SOFT_LISTS_DIR=$MY_OS_PATH_SCRIPTS/software-lists

MY_OS_PATH_GIT=$MY_OS_PATH_BASE/git

MY_OS_PATH_HELP_FILE=$MY_OS_PATH_TEMPFILES/help-file.txt
MY_OS_PATH_WHAT_TO_STOW_FILE=$MY_OS_PATH_TEMPFILES/what-to-stow.txt

# For git module
MY_OS_GIT_ARTIFACT_NAME=archive.zip

MY_OS_GIT_PATH_SOFTWARE_BACKUPS=$MY_OS_PATH_BASE
MY_OS_GIT_ARTIFACT_DIR_SOFTWARE_BACKUPS=software-backups

MY_OS_GIT_PATH_FIREFOX_PROFILES="~/.mozilla"
MY_OS_GIT_ARTIFACT_DIR_BROWSER_PROFILES=firefox

