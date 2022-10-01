MY_OS_PATH_LINK_ROOT=$(lib path symlink-dirs)

lib log banner "Running symlink deployment script"

##############################
# FUNCTIONS
##############################

function lib_os_copy_link {
	local LINK=$1
	local DEST_DIR=$2
	[[ ! -e $DEST_DIR ]] && lib input "Directory $DEST_DIR doesn't exist. Create path to it?" && "mkdir -p $DEST_DIR"
	[[ -e $DEST_DIR && ( ! -d $DEST_DIR ) ]] && lib input "$DEST_DIR exist but is not directory. Remov it?" && "rm -i $DEST_DIR"
	[[ -e $DEST_DIR && ( ! -d $DEST_DIR ) ]] && lib log err "$DEST_DIR still exists and is not a directory. Can't copy!" && return

	F_PATH=$DEST_DIR/${LINK##*/}
    	[[ -e $F_PATH ]] && ls -ld "$F_PATH" && lib input "$F_PATH exists. Remove it? (rm -i $F_PATH)" && "rm -i $F_PATH"
    	[[ -e $F_PATH ]] && ls -ld "$F_PATH" && lib input no-yes "$F_PATH exists. DANGER!!!! Remove it? (rm -rf $F_PATH/)" && "rm -rf $F_PATH/"
	[[ -e $F_PATH ]] && lib log err "$F_PATH still exists. Can't copy!" && return
	lib run "cp -P $LINK $DEST_DIR/"
}

function lib_os_copy_int_wrapper {
	local DEF_SRC="$1"
	local TARGET="$2"

  lib log warn "Default source path:"
  lib log warn "$DEF_SRC"
  lib input "Are you satisfied with default source?" &&
  local SRC="$DEF_SRC" || 
  { lib input value "Input your source path here: "; local SRC="$(lib input get-value)"; }

	lib_os_copy_link "$SRC" "$TARGET"
}

lib log "Trying to remove Documents directory, if it's empty, so it can be changed to symlink"
[[ -d ~/Documents ]] && [[ $(ls -la ~/Documents | wc -l) == 3 ]] && rmdir ~/Documents

# Removing links if exist

lib input "Remove links which are already present?" && {
	lib dir ~
	for link in $(find -maxdepth 1 . -type l); do
		dest_path=$(echo $link | sed 's/^..//' | cut -d / -f 2- | awk -v home=$HOME ' { print home "/" $0 } ')
		lib run "rm $dest_path"
	done
	lib dir cd -
}

# Creating links

lib input "Proceed to creating links?" && {
  lib dir symlink-dirs
	for link in $(find . -type l); do
		dest_path=$(echo $link | sed 's/^..//' | cut -d / -f 2- | sed -E 's/\/?[^/]*$//' | awk -v home=$HOME ' { print home "/" $0 }')
		lib_os_copy_int_wrapper $MY_OS_PATH_LINK_ROOT/$(echo $link | sed 's/^..//') $dest_path
	done
  lib dir cd -
}

