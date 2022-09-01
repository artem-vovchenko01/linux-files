MY_OS_GIT_ARTIFACT_NAME=archive.zip
MY_OS_GIT_PATH_FIREFOX_PROFILES="~/.mozilla/firefox"
MY_OS_GIT_PATH_SOFTWARE_BACKUPS=$MY_OS_PATH_BASE
MY_OS_GIT_ARTIFACT_DIR_BROWSER_PROFILES=3fl1hnwj.default-release
MY_OS_GIT_ARTIFACT_DIR_SOFTWARE_BACKUPS=software-backups

function my_os_lib_git_commit {
  lib log "git status"
  git status
  if ! lib input "Are you satisfied with the status?"; then
    exit 1
  fi

  lib log "git add"
  git add .
  lib log "git commit"
  git commit -m "Commit at $(date)"
}

function my_os_lib_git_get_url {
  case $1 in
    browser-profiles)
      echo "https://github.com/artem-vovchenko01/browser-profiles.git"
      ;;
    vimwiki)
      echo "https://github.com/artem-vovchenko01/vimwiki.git"
      ;;
    linux-files)
      echo "https://github.com/artem-vovchenko01/linux-files.git"
      ;;
    software-backups)
      echo "https://github.com/artem-vovchenko01/software-backups.git"
      ;;
  esac
}

function my_os_lib_git_get_artifact_destination {
  case "$(lib git get-selected-repo)" in
    browser-profiles)
      echo "$MY_OS_GIT_PATH_FIREFOX_PROFILES"
      ;;
    software-backups)
      echo "$MY_OS_GIT_PATH_SOFTWARE_BACKUPS"
      ;;
  esac
}

function my_os_lib_git_get_artifact_dir_name {
  case "$(lib git get-selected-repo)" in
    browser-profiles)
      echo "$MY_OS_GIT_ARTIFACT_DIR_BROWSER_PROFILES"
      ;;
    software-backups)
      echo "$MY_OS_GIT_ARTIFACT_DIR_SOFTWARE_BACKUPS"
      ;;
  esac
}

function my_os_lib_git_artifact_unpack {
  lib log "Trying to unpack artifact from $(lib git get-selected-repo)"
  name_of_extracted_dir=$(zip -sf $MY_OS_GIT_ARTIFACT_NAME | grep -E '.*/$' | head -n1 | tr -d ' ' | tr -d '/')
  artifact_destination="$(my_os_lib_git_get_artifact_destination)"
  ls "${artifact_destination}/${name_of_extracted_dir}" &> /dev/null && {
    lib log warn "Destination ${artifact_destination}/{name_of_extracted_dir} already exists. Won't proceed"
    return
  }
  lib run "unzip $MY_OS_GIT_ARTIFACT_NAME -d $artifact_destination"
}

function my_os_lib_git_archive_artifact {
  lib run "mkdir -p ARCH"
  lib run "zip -re $1.zip "
}

function my_os_lib_git_force_push_artifact {
  REMOTE_URL=$(git remote show origin -n | tr ' ' '\n' | grep https | head -n 1)
  lib run "rm -rf .git"
  lib run "rm -f $MY_OS_GIT_ARTIFACT_NAME"
  lib run "git init"
  lib run "git remote add origin $REMOTE_URL"
  lib run "cp -r $(my_os_lib_git_get_artifact_destination)/$(my_os_lib_git_get_artifact_dir_name) ."
  lib run "zip -re $MY_OS_GIT_ARTIFACT_NAME $(my_os_lib_git_get_artifact_dir_name)"

  lib run "git push -f --set-upstream origin main"
}

function my_os_lib_git_select {
  url=$(my_os_lib_git_get_url $1)
  lib dir $MY_OS_PATH_GIT
  [[ -e $MY_OS_PATH_GIT/"$1" ]] || lib run "git clone $url"
  lib dir "$1"
  MY_OS_GIT_SELECTED_REPO="$1"
  lib log "lib git: repository $MY_OS_GIT_SELECTED_REPO is selected"
}

function my_os_lib_git_get_selected_repo {
  echo "$MY_OS_GIT_SELECTED_REPO"
}

function my_os_lib_git_check_updates {
lib log "Checking if there are update is $(pwd) repo"
  lines=$(git status -s | wc -l)
  if [[ $lines -gt 0 ]]; then
      lib log "There are some updates in this repo!!! Comitting them ..."
      commit
      return 0;
    else
      lib log "There are no updates in this repo"
      return 1;
  fi
}


commit() {
  log "git status"
  git status
  if ! yes-or-no "Are you satisfied with the status?"; then
    exit 1
  fi

  log "git add"
  git add .
  log "git commit"
  git commit -m "Commit at $(date)"
}

check-updates() {
log "Checking if there are update is $(pwd) repo"
  lines=$(git status -s | wc -l)
  if [[ $lines -gt 0 ]]; then
      log "There are some updates in this repo!!! Comitting them ..."
      commit
      return 0;
    else
      log "There are no updates in this repo"
      return 1;
  fi
}

company() {
  archive_name=$(date | tr ' ' '-').zip
  cd ./COMPANY

  if check-updates; then
      log "Zipping COMPANY... "
      cd ..
      zip -re ./ARCHIVES/$archive_name COMPANY/
      cd COMPANY/
    else
      log "COMPANY have no updates, so no zip archive is created. "
  fi

  cd ..
}

# WORKING ON COMPANY NOTES

company

# COMITTING GENERAL NOTES

if check-updates; then
  log "git push"
  git push
fi

