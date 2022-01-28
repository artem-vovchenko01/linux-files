banner "Running symlink deployment script (mainly, for browsers)"

[[ $1 == "-i" ]] && INTERACTIVE=1
[[ -z $INTERACTIVE ]] && msg_info "Running script in non-interactive mode. Pass -i flag for interactive execution."

[[ -n $INTERACTIVE ]] && {
    ask "Continue running this script?" || exit 0
}

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

##############################
# CREATING LINKS
##############################

LINK_ROOT=$SYMLINK_DIRS_PATH

copy_int_wrapper $LINK_ROOT/firefox/.mozilla/firefox ~/.mozilla
copy_int_wrapper $LINK_ROOT/brave/.config/BraveSoftware ~/.config
copy_int_wrapper $LINK_ROOT/brave/.cache/BraveSoftware ~/.cache
copy_int_wrapper $LINK_ROOT/vimwiki/vimwiki ~
copy_int_wrapper $LINK_ROOT/playground/Playground ~
copy_int_wrapper $LINK_ROOT/software/Software ~
copy_int_wrapper $LINK_ROOT/librewolf/.librewolf ~

##############################
# PURGING LINKS IF NEEDED
##############################

[[ -n $INTERACTIVE ]] && {
    ask "Do you need to remove some links?" && {
        exc_int "rm -i ~/.mozilla/firefox"
        exc_int "rm -i ~/.config/BraveSoftware"
        exc_int "rm -i ~/.cache/BraveSoftware"
        exc_int "rm -i ~/vimwiki"
        exc_int "rm -i ~/Playground"
        exc_int "rm -i ~/Software"
        exc_int "rm -i ~/.librewolf"
    }
}

