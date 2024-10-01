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

# Playground
mkdir -p ~/Playground
if [ -d $DATA_DIR ]; then
  ln -sf $DATA_DIR/Playground ~/Playground/shared
fi

# Hyprland
mkdir -vp ~/custom-setup/hyprland

# Pomodoro
if [ -d ~/.pomodoro ]; then
	mkdir -vp ~/custom-setup/pomodoro
	[ ! -f ~/custom-setup/pomodoro/enabled ] && echo false > ~/custom-setup/pomodoro/enabled
	[ ! -f ~/custom-setup/pomodoro/state ] && echo stopped > ~/custom-setup/pomodoro/state
	ln -sf ~/linux-files/scripts/pomodoro/hooks/start ~/.pomodoro/hooks/start
	ln -sf ~/linux-files/scripts/pomodoro/hooks/stop ~/.pomodoro/hooks/stop
	ln -sf ~/linux-files/scripts/pomodoro/hooks/break ~/.pomodoro/hooks/break
fi
