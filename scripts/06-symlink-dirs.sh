#! /usr/bin/env bash
source 00-common.sh

banner "Running symlink deployment script (mainly, for browsers)"

ask "Continue running this script?" || exit 0

##############################
# FUNCTIONS
##############################

function copy_link {
	local LINK=$1
	local DEST_DIR=$2
	[[ ! -e $DEST_DIR ]] && ask "Directory $DEST_DIR doesn't exist. Create path to it?" Y "mkdir -p $DEST_DIR"
	[[ -e $DEST_DIR && ( ! -d $DEST_DIR ) ]] && ask "$DEST_DIR exist but is not directory. Remov it?" N "rm -i $DEST_DIR"
	[[ -e $DEST_DIR && ( ! -d $DEST_DIR ) ]] && msg_err "$DEST_DIR still exists and is not a directory. Can't copy!" && return
	
	F_PATH=$DEST_DIR/${LINK%/*}
	[[ -e $F_PATH ]] && ask "$F_PATH exists. Remove it?" N "rm -rf $F_PATH"
	[[ -e $F_PATH ]] && msg_err "$F_PATH still exists. Can't copy!" && return
	exc_int "cp -P $LINK $DEST_DIR/"
}

function copy_int_wrapper {
	local DEF_SRC="$1"
	local TARGET="$2"
	msg_warn "Default source path:"
	msg_warn "$DEF_SRC"
	ask "Are you satisfied with default source?"
	[[ $? -eq 0 ]] && local SRC="$DEF_SRC" || { ask_value "Input your source path here: "; local SRC="$VALUE"; }
	copy_link "$SRC" "$TARGET"
}

##############################
# CREATING LINKS
##############################

LINK_ROOT=../symlink_dirs

copy_int_wrapper $LINK_ROOT/firefox/.mozilla/firefox ~/.mozilla
copy_int_wrapper $LINK_ROOT/brave/.config/BraveSoftware ~/.config
copy_int_wrapper $LINK_ROOT/brave/.cache/BraveSoftware ~/.cache
copy_int_wrapper $LINK_ROOT/vimwiki/vimwiki ~
copy_int_wrapper $LINK_ROOT/playground/Playground ~
copy_int_wrapper $LINK_ROOT/software/Software ~

##############################
# PURGING LINKS IF NEEDED
##############################

ask "Do you need to remove some links?" && {
	exc_int "rm -i ~/.mozilla/firefox"
	exc_int "rm -i ~/.config/BraveSoftware"
	exc_int "rm -i ~/.cache/BraveSoftware"
	exc_int "rm -i ~/vimwiki"
	exc_int "rm -i ~/Playground"
	exc_int "rm -i ~/Software"
}

