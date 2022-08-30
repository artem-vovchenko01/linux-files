#! /bin/env bash

# UTILITIES
log() {
  lolcat <(echo $1)
}

yes-or-no() {
  log "$1"
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) return 0;;
      No ) return 1;;
    esac
  done
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

