function lib_os_script_setup_software {
  lib log notice "Choose the software lists you want to install:"
  lib input multiple-choice $(ls $MY_OS_PATH_SOFT_LISTS_DIR | grep -v flatpak)
  MY_OS_LIB_SELECTED_SOFT_LIST_FILES="$(lib input get-multiple-choice)"
}

function lib_os_script_setup_manage_git_repos {
  lib log notice "Choose repos you want to configure:"
  lib input multiple-choice $(lib git get-all-repos)
  MY_OS_LIB_SELECTED_REPOS=$(lib input get-multiple-choice)
  # archive password
  lib input secret-value "Provide decryption password:"
  password_attempt_1="$(lib input get-value)"
  lib input secret-value "Repeat the password:"
  [[ "$password_attempt_1" -eq "$(lib input get-value)" ]] || { lib log err "Passwords doesn't match!"; exit; }
  lib settings set zip_passwd_decrypt $(lib input get-value)

  lib input secret-value "Provide encryption password:"
  password_attempt_1="$(lib input get-value)"
  lib input secret-value "Repeat the password:"
  [[ "$password_attempt_1" -eq "$(lib input get-value)" ]] || { lib log err "Passwords doesn't match!"; exit; }
  lib settings set zip_passwd_encrypt $(lib input get-value)
}

