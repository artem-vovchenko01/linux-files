lib log "Working with my git repos ..."
# Firefox profile
lib git select browser-profiles-brave
lib input "Close Brave for working with it's profile?" && {
  lib run "pkill brave"
  [[ ! -e $(lib git get-artifact-path) ]] && lib git unpack-artifact
  lib git update-artifact
  lib git force-push-artifact
}

# Firefox profile
lib git select browser-profiles
lib input "Close Firefox for working with it's profile?" && {
  lib run "killall firefox"
  [[ ! -e $(lib git get-artifact-path) ]] && lib git unpack-artifact
  lib git update-artifact
  lib git force-push-artifact
}

# Backups
lib git select software-backups
[[ ! -e $(lib git get-artifact-path) ]] && lib git unpack-artifact
lib git update-artifact
lib git force-push-artifact

# Vimwiki
lib git select vimwiki
