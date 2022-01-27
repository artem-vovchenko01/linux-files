DATA_PATH=..
function ask {
	echo $1
	echo -n "Your choice: "
	read key 
}

function check_path_exists {
SKIP_REMOVE=0
if [[ -e $1 || -L $1  ]]; then
	ask "$1 path isn't empty. It's recommended to backup it to other place and then remove here. Press Y to remove. "
	if [ ${key:-N} = "Y" ]; then
		rm -r $1
		echo "Done. "
	else
		SKIP_REMOVE=1
	fi
fi
}

function link {
	if [ ! $SKIP_REMOVE = 1 ]; then
		ln -s $PWD/$1 $2
		echo "Link created: $(ls -l $2)"
	else 
		echo "Skipped linking. "
	fi
	echo
}

if [ ! -d ../private_data ]; then
	ask "This repo was intended for personal use and meant to be used with private cloned repo ../private_data. Type Y if you want to proceed without private data."
	if [ ! $key = 'Y' ]; then 
		exit
	else 
		PUBLIC_MODE=1
	fi
fi 

# VIMWIKI

VIMWIKI_PATH=$HOME/vimwiki
check_path_exists $VIMWIKI_PATH 
link ${DATA_PATH}/vimwiki $VIMWIKI_PATH 

# NEOVIM

NVIM_PATH=$HOME/.config/nvim
check_path_exists $NVIM_PATH 
link ${DATA_PATH}/.config/nvim $NVIM_PATH

# i3 

I3_PATH=$HOME/.config/i3
check_path_exists $HOME/.i3
check_path_exists $I3_PATH
link ${DATA_PATH}/.config/i3 $I3_PATH

# i3blocks

I3_BLOCKS_PATH=$HOME/.config/i3blocks
check_path_exists $I3_BLOCKS_PATH
link ${DATA_PATH}/.config/i3blocks $I3_BLOCKS_PATH

# Personal scripts

SCRIPTS_PATH=$HOME/.local/bin/scripts
check_path_exists $SCRIPTS_PATH
link ${DATA_PATH}/.local/bin/scripts $SCRIPTS_PATH



