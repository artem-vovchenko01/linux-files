#!/usr/bin/env bash
set -euxo pipefail

SYNCTHING_DIR=/mnt/syncthing/Syncthing

############################################
# CONFIGS
############################################

# Shell
ln -sf ~/linux-files/dotfiles/bash/.shrc.part

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

############################################
# CUSTOM SETUP DIRECTORY
############################################
mkdir -vp ~/custom-setup/hyprland

# Pomodoro
mkdir -vp ~/custom-setup/pomodoro
[ ! -f ~/custom-setup/pomodoro/enabled ] && echo false > ~/custom-setup/pomodoro/enabled
[ ! -f ~/custom-setup/pomodoro/state ] && echo stopped > ~/custom-setup/pomodoro/state
ln -sf ~/linux-files/scripts/pomodoro/hooks/start ~/.pomodoro/hooks/start
ln -sf ~/linux-files/scripts/pomodoro/hooks/stop ~/.pomodoro/hooks/stop
ln -sf ~/linux-files/scripts/pomodoro/hooks/break ~/.pomodoro/hooks/break

############################################
# SETUP FOLDERS
############################################
mkdir -p ~/local-git-server
mkdir -p ~/Playground
ln -sf $SYNCTHING_DIR/Playground ~/Playground/Syncthing
