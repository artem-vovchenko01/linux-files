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
      lib path browser-profiles
      ;;
    software-backups)
      lib path software-backups
      ;;
  esac
}

function my_os_lib_git_get_artifact_path {
  echo $(my_os_lib_git_get_artifact_destination)/$(my_os_lib_git_get_artifact_dir_name)
}

function my_os_lib_git_get_artifact_dir_name {
  case "$(lib git get-selected-repo)" in
    browser-profiles)
      echo $MY_OS_GIT_ARTIFACT_DIR_BROWSER_PROFILES
      ;;
    software-backups)
      echo $MY_OS_GIT_ARTIFACT_DIR_SOFTWARE_BACKUPS
      ;;
  esac
}

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

function my_os_lib_git_artifact_unpack {
  lib log "Trying to unpack artifact from $(lib git get-selected-repo)"
  name_of_extracted_dir=$(zip -sf $MY_OS_GIT_ARTIFACT_NAME | grep -E '.*/$' | head -n1 | tr -d ' ' | tr -d '/')
  artifact_destination="$(my_os_lib_git_get_artifact_destination)"
  lib run "mkdir -p ${artifact_destination}"
  ls "${artifact_destination}/${name_of_extracted_dir}" &> /dev/null && {
    lib log warn "Destination ${artifact_destination}/${name_of_extracted_dir} already exists. Won't proceed"
    return
  }
  lib log "Unzipping ..."
  unzip -P $(lib settings get zip_passwd) $MY_OS_GIT_ARTIFACT_NAME -d $artifact_destination
}

function my_os_lib_git_update_artifact {
  REMOTE_URL=$(git remote show origin -n | tr ' ' '\n' | grep https | head -n 1)
  lib run "rm -rf .git"
  lib run "rm -f $MY_OS_GIT_ARTIFACT_NAME"
  lib run "git init"
  lib run "git remote add origin $REMOTE_URL"
  lib run "cp -r $(my_os_lib_git_get_artifact_destination)/$(my_os_lib_git_get_artifact_dir_name) ."
  lib log "Zipping ..."
  zip -P $(lib settings get zip_passwd) -r $MY_OS_GIT_ARTIFACT_NAME $(my_os_lib_git_get_artifact_dir_name)
  lib run "rm -rf $(my_os_lib_git_get_artifact_dir_name)"
  lib git commit
}

function my_os_lib_git_force_push_artifact {
  [[ -e $MY_OS_GIT_ARTIFACT_NAME ]] &&
  lib run "git push -f --set-upstream origin main" ||
  lib log err "There is no $MY_OS_GIT_ARTIFACT_NAME found in the repo directory! Won't force push"
}

function my_os_lib_git_select {
  url=$(my_os_lib_git_get_url $1)
  lib dir cd $MY_OS_PATH_GIT
  [[ -e $MY_OS_PATH_GIT/"$1" ]] || { lib log warn "The repository $1 is not present. Cloning it ..."; lib run "git clone $url"; }
  lib dir cd "$1"
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

