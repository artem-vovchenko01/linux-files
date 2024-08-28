#!/usr/bin/env bash
set -euxo pipefail

mkdir -p ~/custom-setup/hyprland/{pomodoro,state}

############################################
# CONFIGS
############################################

# Hyprland
mkdir -p ~/.config/hypr
ln -sf ~/linux-files/dotfiles/hyprland/hyprland.conf ~/.config/hypr/hyprland.conf
ln -sf ~/linux-files/dotfiles/hyprland/hypridle.conf ~/.config/hypr/hypridle.conf
ln -sf ~/linux-files/dotfiles/hyprland/hyprpaper.conf ~/.config/hypr/hyprpaper.conf

# Mako
mkdir -p ~/.config/mako
ln -sf ~/linux-files/dotfiles/mako/.config/mako/config ~/.config/mako/config

# Lunarvim
mkdir -p ~/.config/lvim
ln -sf ~/linux-files/dotfiles/lunarvim/.config/lvim/config.lua ~/.config/lvim/config.lua
