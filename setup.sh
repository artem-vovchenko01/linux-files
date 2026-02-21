#!/usr/bin/env bash
set -euxo pipefail

DATA_DIR=/mnt/data/data

############################################
# CONFIGS
############################################

# Shell
ln -sf ~/linux-files/dotfiles/bash/.shrc.part ~/.shrc.part.sh
grep .shrc.part.sh ~/.bashrc || echo "source ~/.shrc.part.sh" >> ~/.bashrc

# SSH
mkdir -vp ~/.ssh
ln -sf ~/linux-files/dotfiles/ssh/.ssh/config ~/.ssh/config

# Hyprland
mkdir -vp ~/.config/hypr
ln -sf ~/linux-files/dotfiles/hyprland/hyprland.conf ~/.config/hypr/hyprland.conf
ln -sf ~/linux-files/dotfiles/hyprland/hypridle.conf ~/.config/hypr/hypridle.conf
ln -sf ~/linux-files/dotfiles/hyprland/hyprpaper.conf ~/.config/hypr/hyprpaper.conf

# Mako
mkdir -vp ~/.config/mako
ln -sf ~/linux-files/dotfiles/mako/.config/mako/config ~/.config/mako/config

# Dunst
mkdir -vp ~/.config/dunst
ln -sf ~/linux-files/dotfiles/dunst/dunstrc ~/.config/dunst/dunstrc

# Lunarvim
mkdir -vp ~/.config/lvim
ln -sf ~/linux-files/dotfiles/lunarvim/.config/lvim/config.lua ~/.config/lvim/config.lua

# Git
ln -sf ~/linux-files/dotfiles/git/.gitconfig ~/.gitconfig

# Wofi
mkdir -vp ~/.config/wofi
ln -sf ~/linux-files/dotfiles/wofi/.config/wofi/config ~/.config/wofi/config
ln -sf ~/linux-files/dotfiles/wofi/.config/wofi/config-app ~/.config/wofi/config-app
ln -sf ~/linux-files/dotfiles/wofi/.config/wofi/config-wallpapers ~/.config/wofi/config-wallpapers
ln -sf ~/linux-files/dotfiles/wofi/.config/wofi/style.css ~/.config/wofi/style.css

# Waybar
mkdir -vp ~/.config/waybar
ln -sf ~/linux-files/dotfiles/waybar/.config/waybar/config.jsonc ~/.config/waybar/config.jsonc
ln -sf ~/linux-files/dotfiles/waybar/.config/waybar/style.css ~/.config/waybar/style.css

# lf
mkdir -p ~/.config/lf
ln -sf ~/linux-files/dotfiles/lf/.config/lf/lfrc ~/.config/lf/lfrc

# Kitty
mkdir -p ~/.config/kitty
ln -sf ~/linux-files/dotfiles/kitty/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf

# VSCode
mkdir -p ~/.config/{"Code - OSS",Code}/User/
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/"Code - OSS"/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/"Code - OSS"/User/keybindings.json
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/Code/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/Code/User/keybindings.json
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/Cursor/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/Cursor/User/keybindings.json

############################################
# PACKAGES
############################################
if command -v pacman 2>&1 > /dev/null; then
	echo Pacman detected
	# thunar-archive-plugin - for enabling archiving options in thunar
	# tumbler ffmpegthumbnailer libgsf file-roller - for making thumbnails in thunar work
	PACKAGES="brightnessctl less libnotify wob hyprpaper hypridle git vifm neovim zoxide fzf kitty wl-clipboard imv grim slurp waybar hypridle otf-font-awesome inetutils thunar tumbler ffmpegthumbnailer libgsf file-roller thunar-archive-plugin zip unzip gedit zathura zathura-pdf-mupdf tesseract-data-eng cliphist tldr man-db man-pages"
	echo $PACKAGES
	read -r -p "Install the above packages? [y/N]: " ans
	case "${ans,,}" in
	  y|yes)
	    sudo pacman -Sy $PACKAGES
	    ;;
	  *)
	    echo "Cancelled."
	    ;;
	esac
fi

############################################
# FONTS
############################################
read -r -p "Install fonts? [y/N]: " ans
case "${ans,,}" in
  y|yes)
    sudo pacman -S ttf-hack-nerd inter-font noto-fonts noto-fonts-emoji
    mkdir -vp ~/.config/fontconfig
    ln -sf ~/linux-files/dotfiles/fontconfig/.config/fontconfig/fonts.conf ~/.config/fontconfig/fonts.conf
    fc-cache -fv
    fc-match sans-serif
    fc-match system-ui
    fc-match monospace
    ;;
  *)
    echo "Cancelled."
    ;;
esac

############################################
# SETUP FOLDERS
############################################

# Local git
mkdir -p ~/local-git-server
echo "Example git file for client repo:"
echo =========================================
cat <<EOF
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
[remote "pc"]
	url = artem@192.168.0.84:/home/artem/local-git-server/logseq-personal
	fetch = +refs/heads/*:refs/remotes/pc/*
[branch "main"]
	remote = pc
	merge = refs/heads/main
EOF
echo =========================================
read -p "Press enter to continue ... "

# Playground
mkdir -p ~/Playground
#if [ -d $DATA_DIR ]; then
#  ln -sf $DATA_DIR/Playground ~/Playground/shared
#fi

# Logseq
mkdir -vp ~/logseq

# Hyprland
mkdir -vp ~/custom-setup/hyprland

# Pomodoro
#if [ -d ~/.pomodoro ]; then
#	mkdir -vp ~/custom-setup/pomodoro
#	[ ! -f ~/custom-setup/pomodoro/enabled ] && echo false > ~/custom-setup/pomodoro/enabled
#	[ ! -f ~/custom-setup/pomodoro/state ] && echo stopped > ~/custom-setup/pomodoro/state
#	ln -sf ~/linux-files/scripts/pomodoro/hooks/start ~/.pomodoro/hooks/start
#	ln -sf ~/linux-files/scripts/pomodoro/hooks/stop ~/.pomodoro/hooks/stop
#	ln -sf ~/linux-files/scripts/pomodoro/hooks/break ~/.pomodoro/hooks/break
#fi
