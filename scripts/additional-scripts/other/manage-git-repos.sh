function my_os_lib_git_process_browser_profiles {
  lib git select browser-profiles
  lib input "Close Firefox for working with it's profile?" && {
    lib run "killall firefox"
    [[ ! -e $(lib git get-artifact-path) ]] && lib git unpack-artifact
    lib git update-artifact
    lib git force-push-artifact
  }
}

function my_os_lib_git_process_browser_profiles_brave {
  lib git select browser-profiles-brave
  lib input "Close Brave for working with it's profile?" && {
    lib run "pkill brave"
    [[ ! -e $(lib git get-artifact-path) ]] && lib git unpack-artifact
    lib git update-artifact
    lib git force-push-artifact
  }
}

function my_os_lib_git_process_vimwiki {
  lib git select vimwiki
}

function my_os_lib_git_process_linux_files {
  lib git select linux-files
}

function my_os_lib_git_process_software_backups {
  lib git select software-backups
  [[ ! -e $(lib git get-artifact-path) ]] && lib git unpack-artifact
  lib git update-artifact
  lib git force-push-artifact
}

lib log "Working with my git repos ..."

for repo in $MY_OS_LIB_SELECTED_REPOS; do
  [[ $repo == "vimwiki" ]] && my_os_lib_git_process_vimwiki
  [[ $repo == "browser-profiles" ]] && my_os_lib_git_process_browser_profiles
  [[ $repo == "browser-profiles-brave" ]] && my_os_lib_git_process_browser_profiles_brave
  [[ $repo == "software-backups" ]] && my_os_lib_git_process_software_backups
  [[ $repo == "linux-files" ]] && my_os_lib_git_process_linux_files
done

