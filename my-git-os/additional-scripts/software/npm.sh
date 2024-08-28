lib log "Settings up npm ..."

##############################
# NPM EACCESS ISSUE
##############################

lib log "Fixing npm EACCESS issue ..."

lib run "npm config set prefix ~/.npm-global"

##############################
# NPM PACKAGES
##############################

lib log "Installing npm packages of choice ..."

lib run "npm install -g git-file-history"

