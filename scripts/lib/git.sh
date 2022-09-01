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
      ;;
    vimwiki)
      ;;
    linux-files)
      ;;
  esac
}

function my_os_lib_git_select {
  url=$(my_os_lib_git_get_url $1)
  [[ -e $MY_OS_PATH_GIT/"$1" ]] || 
  lib dir }

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

