LINK_ROOT=$SYMLINK_DIRS_PATH

banner "Running symlink deployment script (mainly, for browsers)"

##############################
# FUNCTIONS
##############################

function copy_link {
	local LINK=$1
	local DEST_DIR=$2
	[[ ! -e $DEST_DIR ]] && ask "Directory $DEST_DIR doesn't exist. Create path to it?" Y "mkdir -p $DEST_DIR"
	[[ -e $DEST_DIR && ( ! -d $DEST_DIR ) ]] && ask "$DEST_DIR exist but is not directory. Remov it?" N "rm -i $DEST_DIR"
	[[ -e $DEST_DIR && ( ! -d $DEST_DIR ) ]] && msg_err "$DEST_DIR still exists and is not a directory. Can't copy!" && return

	F_PATH=$DEST_DIR/${LINK##*/}
    	[[ -e $F_PATH ]] && ls -ld "$F_PATH" && ask "$F_PATH exists. Remove it? (rm -i $F_PATH)" N "rm -i $F_PATH"
    	[[ -e $F_PATH ]] && ls -ld "$F_PATH" && ask "$F_PATH exists. DANGER!!!! Remove it? (rm -rf $F_PATH/)" N "rm -rf $F_PATH/"
	[[ -e $F_PATH ]] && msg_err "$F_PATH still exists. Can't copy!" && return
	exc "cp -P $LINK $DEST_DIR/"
}

function copy_int_wrapper {
	local DEF_SRC="$1"
	local TARGET="$2"
    	[[ -n $INTERACTIVE ]] && {
		msg_warn "Default source path:"
		msg_warn "$DEF_SRC"
		ask "Are you satisfied with default source?"
		[[ $? -eq 0 ]] && local SRC="$DEF_SRC" || { ask_value "Input your source path here: "; local SRC="$VALUE"; }
    	}
    	[[ -z $INTERACTIVE ]] && local SRC="$DEF_SRC"
	copy_link "$SRC" "$TARGET"
}

# Removing links if exist

ask "Remove links which are already present?" && {
	cd $SYMLINK_DIRS_PATH
	for link in $(find . -type l); do
		dest_path=$(echo $link | sed 's/^..//' | cut -d / -f 2- | awk -v home=$HOME ' { print home "/" $0 } ')
		exc_ignoreerr "rm $dest_path"
	done
	cd -
}

# Creating links

ask "Proceed to creating links?" && {
	cd $SYMLINK_DIRS_PATH
	for link in $(find . -type l); do
		dest_path=$(echo $link | sed 's/^..//' | cut -d / -f 2- | sed -E 's/\/?[^/]*$//' | awk -v home=$HOME ' { print home "/" $0 }')
		copy_int_wrapper $LINK_ROOT/$(echo $link | sed 's/^..//') $dest_path
	done
	cd -
}

