CURRENT_PROFILE=3fl1hnwj.default-release

msg_info "Current Firefox profile is: $CURRENT_PROFILE"

if ls ~/.mozilla/firefox/$CURRENT_PROFILE &> /dev/null; then
  # Shut down firefox
  msg_info "Trying to shutdown Firefox ..."  
  exc_ignoreerr "killall firefox"

  # Save remote URL
  exc "cd ~/.my-git-os/browser-profiles"
  REMOTE_URL=$(git remote show origin -n | tr ' ' '\n' | grep https | head -n 1)

  # Recreate repo
  msg_info "Recreating the repository with profile"
  rm -rf ~/.my-git-os/browser-profiles/* ~/.my-git-os/browser-profiles/.git
  git init
  git remote add origin $REMOTE_URL

  # Copy firefox profile
  msg_info "Copying profile"
  cp -r ~/.mozilla/firefox/$CURRENT_PROFILE ~/.my-git-os/browser-profiles/
  cp -r ~/.mozilla/firefox/profiles.ini ~/.my-git-os/browser-profiles/

  # Zipping the profile
  ls 
  ARCHIVE_CONTENTS=$(echo *)
  zip -re profile.zip $ARCHIVE_CONTENTS
  rm -rf $ARCHIVE_CONTENTS

  # Comitting and pushing
  commit
  git push -f --set-upstream origin main
else 
  msg_err "Can't find current Firefox profile!"
fi

