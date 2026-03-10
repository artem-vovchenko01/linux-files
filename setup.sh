#!/usr/bin/env bash
set -euxo pipefail

DATA_DIR=/mnt/data/data

############################################
# PACKAGE MANAGER DETECTION
############################################
if command -v pacman &>/dev/null; then
	PKG_MGR=pacman
	pkg_install() { sudo pacman -Sy "$@"; }
elif command -v apt &>/dev/null; then
	PKG_MGR=apt
	pkg_install() { sudo apt update && sudo apt install -y "$@"; }
elif command -v dnf &>/dev/null; then
	PKG_MGR=dnf
	pkg_install() { sudo dnf install -y "$@"; }
elif command -v zypper &>/dev/null; then
	PKG_MGR=zypper
	pkg_install() { sudo zypper install -y "$@"; }
else
	PKG_MGR=unknown
	pkg_install() { echo "No supported package manager found. Install manually: $*"; return 1; }
fi
echo "Detected package manager: $PKG_MGR"

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

# Foot
mkdir -p ~/.config/foot
ln -sf ~/linux-files/dotfiles/foot/.config/foot/foot.ini ~/.config/foot/foot.ini

# VSCode
mkdir -p ~/.config/{"Code - OSS",Code,Cursor}/User/
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/"Code - OSS"/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/"Code - OSS"/User/keybindings.json
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/Code/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/Code/User/keybindings.json
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/Cursor/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/Cursor/User/keybindings.json

############################################
# PACKAGES
############################################
# Common packages (same name across distros)
PACKAGES_COMMON="brightnessctl less wob hyprpaper hypridle git vifm neovim zoxide fzf kitty foot imv grim slurp waybar socat thunar tumbler ffmpegthumbnailer file-roller thunar-archive-plugin zip unzip gedit zathura cliphist tldr man-db"
# thunar-archive-plugin - for enabling archiving options in thunar
# tumbler ffmpegthumbnailer file-roller - for making thumbnails in thunar work

# Distro-specific packages (different names across distros)
case "$PKG_MGR" in
	pacman)
		PACKAGES_DISTRO="libnotify wl-clipboard otf-font-awesome inetutils libgsf zathura-pdf-mupdf tesseract-data-eng man-pages"
		;;
	apt)
		PACKAGES_DISTRO="libnotify-bin wl-clipboard fonts-font-awesome inetutils-tools libgsf-1-common zathura-pdf-poppler tesseract-ocr-eng man"
		;;
	dnf)
		PACKAGES_DISTRO="libnotify wl-clipboard fontawesome-fonts inetutils libgsf zathura-pdf-mupdf tesseract-langpack-eng man-pages"
		;;
	zypper)
		PACKAGES_DISTRO="libnotify-tools wl-clipboard fontawesome-fonts inetutils libgsf-1 zathura-plugin-pdf-mupdf tesseract-ocr-traineddata-english man-pages"
		;;
	*)
		PACKAGES_DISTRO=""
		;;
esac
PACKAGES="$PACKAGES_COMMON $PACKAGES_DISTRO"
if [[ -n "$PACKAGES" ]]; then
	echo "$PACKAGES"
	read -r -p "Install the above packages? [y/N]: " ans
	case "${ans,,}" in
	  y|yes)
	    pkg_install $PACKAGES
	    ;;
	  *)
	    echo "Cancelled."
	    ;;
	esac
fi

############################################
# FONTS
############################################
case "$PKG_MGR" in
	pacman)  FONT_PACKAGES="ttf-hack-nerd inter-font noto-fonts noto-fonts-emoji" ;;
	apt)     FONT_PACKAGES="fonts-hack fonts-inter fonts-noto fonts-noto-color-emoji" ;;
	dnf)     FONT_PACKAGES="google-noto-sans-fonts google-noto-emoji-fonts inter-fonts" ;;
	zypper)  FONT_PACKAGES="google-noto-sans-fonts google-noto-coloremoji-fonts" ;;
	*)       FONT_PACKAGES="" ;;
esac
read -r -p "Install fonts? [y/N]: " ans
case "${ans,,}" in
  y|yes)
    if [[ -n "$FONT_PACKAGES" ]]; then
      pkg_install $FONT_PACKAGES
    else
      echo "Unknown package manager — install fonts manually."
    fi
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
