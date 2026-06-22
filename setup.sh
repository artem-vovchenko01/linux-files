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
	# --skip-unavailable: a single unknown name shouldn't abort the whole batch
	pkg_install() { sudo dnf install -y --skip-unavailable "$@"; }
elif command -v zypper &>/dev/null; then
	PKG_MGR=zypper
	pkg_install() { sudo zypper install -y "$@"; }
else
	PKG_MGR=unknown
	pkg_install() { echo "No supported package manager found. Install manually: $*"; return 1; }
fi
echo "Detected package manager: $PKG_MGR"

pkg_is_installed() {
	case "$PKG_MGR" in
		pacman)
			pacman -Qq "$1" &>/dev/null
			;;
		apt)
			dpkg -s "$1" &>/dev/null
			;;
		dnf|zypper)
			rpm -q "$1" &>/dev/null
			;;
		*)
			return 1
			;;
	esac
}

pkg_ensure_installed() {
	local missing=()
	local pkg

	for pkg in "$@"; do
		if pkg_is_installed "$pkg"; then
			echo "Already installed: $pkg"
		else
			missing+=("$pkg")
		fi
	done

	if (( ${#missing[@]} > 0 )); then
		pkg_install "${missing[@]}"
	fi
}

install_root_file() {
	local src="$1"
	local dst="$2"
	local mode="${3:-0644}"

	sudo install -D -m "$mode" "$src" "$dst"
}

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

# Neovim
ln -sfn ~/linux-files/dotfiles/nvim/.config/nvim ~/.config/nvim

# Git
ln -sf ~/linux-files/dotfiles/git/.gitconfig ~/.gitconfig

# Git credential helper: ~/.gitconfig sets `credential.helper = libsecret` so
# HTTPS credentials land in the Secret Service keyring (gnome-keyring/KWallet)
# instead of being re-prompted every fetch/push. Git finds the helper binary in
# its exec dir; only the package providing it differs per distro. On Debian/
# Ubuntu the package ships source only, so build it from git's contrib tree.
case "$PKG_MGR" in
	pacman) GIT_CRED_PKGS="libsecret" ;;             # helper bundled in `git`
	dnf)    GIT_CRED_PKGS="git-credential-libsecret" ;;
	apt)    GIT_CRED_PKGS="libsecret-1-0" ;;
	zypper) GIT_CRED_PKGS="libsecret-1-0" ;;
	*)      GIT_CRED_PKGS="" ;;
esac
[ -n "$GIT_CRED_PKGS" ] && pkg_ensure_installed $GIT_CRED_PKGS

# Debian/Ubuntu ship the helper as source only — git drops it under contrib but
# doesn't compile it. Don't pull in a toolchain here; just point the way.
if [ ! -x "$(git --exec-path)/git-credential-libsecret" ] && ! command -v git-credential-libsecret &>/dev/null; then
	echo "git-credential-libsecret helper not found. On Debian/Ubuntu build it:"
	echo "  sudo make -C /usr/share/doc/git/contrib/credential/libsecret"
fi

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

# Ptyxis (Fedora default terminal): settings live in dconf, not a file, so we
# write the 10M-line scrollback into the default profile instead of symlinking.
if command -v dconf >/dev/null; then
  PTYXIS_UUID=$(dconf read /org/gnome/Ptyxis/default-profile-uuid | tr -d "'")
  if [ -n "$PTYXIS_UUID" ]; then
    PTYXIS_P=/org/gnome/Ptyxis/Profiles/$PTYXIS_UUID/
    dconf write "${PTYXIS_P}limit-scrollback" true
    dconf write "${PTYXIS_P}scrollback-lines" 10000000
  fi
fi

# VSCode
mkdir -p ~/.config/{"Code - OSS",Code,Cursor}/User/
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/"Code - OSS"/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/"Code - OSS"/User/keybindings.json
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/Code/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/Code/User/keybindings.json
ln -sf ~/linux-files/dotfiles/code/settings.json ~/.config/Cursor/User/settings.json
ln -sf ~/linux-files/dotfiles/code/keybindings.json ~/.config/Cursor/User/keybindings.json

# Tmux
ln -sf ~/linux-files/dotfiles/tmux/tmux.conf ~/.tmux.conf

# AI agents (shared global instructions)
AI_GLOBAL=~/linux-files/ai/CLAUDE_GLOBAL_CONFIG.md

# Claude Code
[ -d ~/.claude ] && ln -sf "$AI_GLOBAL" ~/.claude/CLAUDE.md

# Codex
[ -d ~/.codex ] && ln -sf "$AI_GLOBAL" ~/.codex/AGENTS.md

# OpenCode
[ -d ~/.opencode ] && ln -sf "$AI_GLOBAL" ~/.opencode/AGENTS.md
mkdir -vp ~/.config/opencode
ln -sf ~/linux-files/dotfiles/opencode/opencode.json ~/.config/opencode/opencode.json

# Syncthing (config + device keys live in ~/DATA/IT, database stays local)
# config.xml is NOT symlinked: Syncthing rewrites it via atomic rename, which
# replaces a symlink with a real file. Instead we point its config dir
# (STCONFDIR) at ~/DATA/IT via a systemd drop-in and keep the database
# (STDATADIR) on local storage. On a fresh machine the config + device identity
# can also be restored from a backup left on the HDD (see syncthing-config-backup).
mkdir -vp ~/DATA
SYNCTHING_SRC=~/DATA/IT/configs/syncthing
SYNCTHING_DROPIN=~/linux-files/systemd-units/syncthing.service.d/override.conf
SYNCTHING_BACKUP_NAME=syncthing-config-backup

# Look for a config backup on any mounted HDD partition.
syncthing_hdd_backup=""
for m in /run/media/"$USER"/*/; do
	if [ -f "$m$SYNCTHING_BACKUP_NAME/config.xml" ]; then
		syncthing_hdd_backup="$m$SYNCTHING_BACKUP_NAME"
		break
	fi
done

apply_syncthing_redirect() {
	# Don't silently shadow a different identity already in the default location.
	for d in ~/.local/state/syncthing ~/.config/syncthing; do
		if [ -f "$d/config.xml" ]; then
			echo "Existing Syncthing identity at $d would be shadowed by ~/DATA/IT."
			read -r -p "Repoint Syncthing config to ~/DATA/IT and restart? [y/N]: " ans
			case "${ans,,}" in
				y|yes) ;;
				*) echo "Left Syncthing untouched."; return ;;
			esac
			break
		fi
	done
	systemctl --user stop syncthing 2>/dev/null || true
	mkdir -vp ~/.config/systemd/user/syncthing.service.d
	ln -sfv "$SYNCTHING_DROPIN" ~/.config/systemd/user/syncthing.service.d/override.conf
	systemctl --user daemon-reload
	systemctl --user enable --now syncthing 2>/dev/null || true
	echo "Syncthing config dir set to $SYNCTHING_SRC; service (re)started."
}

if [ -f "$SYNCTHING_DROPIN" ]; then
	if [ -f "$SYNCTHING_SRC/config.xml" ]; then
		# A config is already present locally (e.g. ~/DATA/IT synced from a peer).
		if [ -n "$syncthing_hdd_backup" ]; then
			echo "Syncthing: a local config already exists at $SYNCTHING_SRC (synced IT folder)."
			echo "          An HDD backup also exists at $syncthing_hdd_backup — ignoring it; the synced copy wins."
		fi
		echo "Syncthing: will repoint the service at $SYNCTHING_SRC and restart."
		apply_syncthing_redirect
	elif [ -n "$syncthing_hdd_backup" ]; then
		echo "Syncthing: no synced ~/DATA/IT config; restoring from HDD backup at $syncthing_hdd_backup."
		mkdir -vp "$SYNCTHING_SRC"
		cp -v "$syncthing_hdd_backup"/* "$SYNCTHING_SRC"/
		apply_syncthing_redirect
	else
		echo "Syncthing: backup not found — no HDD backup ($SYNCTHING_BACKUP_NAME) and no synced ~/DATA/IT."
		echo "          Install syncthing, let the IT folder sync (or plug in the HDD backup), then re-run."
	fi
fi


############################################
# PACKAGES
############################################
# Common packages (same name across distros)
PACKAGES_COMMON="less git git-delta vifm neovim zoxide fzf direnv kitty foot imv nemo thunar tumbler ffmpegthumbnailer file-roller thunar-archive-plugin zip unzip gedit zathura tealdeer man-db syncthing htop btop"
# thunar-archive-plugin - for enabling archiving options in thunar
# tumbler ffmpegthumbnailer file-roller - for making thumbnails in thunar work

# Distro-specific packages (different names across distros)
case "$PKG_MGR" in
	pacman)
		PACKAGES_DISTRO="pacman-contrib libnotify otf-font-awesome inetutils libgsf zathura-pdf-mupdf tesseract-data-eng man-pages starship"
		;;
	apt)
		PACKAGES_DISTRO="libnotify-bin fonts-font-awesome inetutils-tools libgsf-1-common zathura-pdf-poppler tesseract-ocr-eng man"
		;;
	dnf)
		# Fedora: -free-fonts is the light icon set (-all/-web also pull web/JS/brands);
		# inetutils/hostname dropped — hostname ships in the base install.
		# fuse-libs: Fedora ships only fuse3, but type-2 AppImages link against the
		# FUSE 2 ABI (libfuse.so.2), so they fail to launch without it.
		PACKAGES_DISTRO="libnotify fontawesome-6-free-fonts libgsf zathura-pdf-mupdf tesseract-langpack-eng man-pages fuse-libs"
		;;
	zypper)
		PACKAGES_DISTRO="libnotify-tools fontawesome-fonts inetutils libgsf-1 zathura-plugin-pdf-mupdf tesseract-ocr-traineddata-english man-pages"
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
# HYPRLAND PACKAGES
############################################
HYPR_COMMON="brightnessctl wob grim slurp waybar socat cliphist blueman"
case "$PKG_MGR" in
	pacman)  HYPR_DISTRO="wl-clipboard hyprpaper hypridle" ;;
	apt)     HYPR_DISTRO="wl-clipboard" ;;
	# Fedora: hyprpaper/hypridle aren't in the main repos — enable COPR
	# solopasha/hyprland (or use swaybg/swayidle) if you want them.
	dnf)     HYPR_DISTRO="wl-clipboard" ;;
	zypper)  HYPR_DISTRO="wl-clipboard" ;;
	*)       HYPR_DISTRO="" ;;
esac
HYPR_PACKAGES="$HYPR_COMMON $HYPR_DISTRO"
echo "$HYPR_PACKAGES"
read -r -p "Install Hyprland packages? [y/N]: " ans
case "${ans,,}" in
  y|yes)
    pkg_install $HYPR_PACKAGES
    ;;
  *)
    echo "Cancelled."
    ;;
esac

############################################
# FONTS
############################################
case "$PKG_MGR" in
	pacman)  FONT_PACKAGES="ttf-hack-nerd inter-font noto-fonts noto-fonts-emoji" ;;
	apt)     FONT_PACKAGES="fonts-hack fonts-inter fonts-noto fonts-noto-color-emoji" ;;
	dnf)     FONT_PACKAGES="google-noto-sans-fonts google-noto-emoji-fonts rsms-inter-fonts" ;;
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
    # Nerd Font for lvim/terminal/waybar icons. pacman ships ttf-hack-nerd;
    # other distros don't package it, so fetch it into the user font dir.
    if ! fc-list | grep -qi "Hack Nerd"; then
      NERD_DIR=~/.local/share/fonts/HackNerd
      mkdir -vp "$NERD_DIR"
      NERD_URL=https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
      curl -fsSL "$NERD_URL" -o /tmp/Hack.zip
      unzip -o /tmp/Hack.zip -d "$NERD_DIR"
      rm -f /tmp/Hack.zip
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
# OOM KILLER
############################################
read -r -p "Configure oom killer? [y/N]: " ans
case "${ans,,}" in
  y|yes)
    case "$PKG_MGR" in
      pacman|apt|dnf)
        pkg_ensure_installed earlyoom
        ;;
      *)
        echo "earlyoom package installation is not configured for $PKG_MGR. Install it manually."
        ;;
    esac

    if command -v systemctl &>/dev/null; then
      install_root_file ~/linux-files/system-config/earlyoom/etc/default/earlyoom /etc/default/earlyoom
      install_root_file ~/linux-files/system-config/earlyoom/etc/systemd/system/earlyoom.service.d/override.conf /etc/systemd/system/earlyoom.service.d/override.conf
      sudo systemctl daemon-reload
      sudo systemctl enable --now earlyoom
      sudo systemctl restart earlyoom
    else
      echo "systemctl not found; skipping service activation."
    fi
    ;;
  *)
    echo "Cancelled."
    ;;
esac

############################################
# APPIMAGELAUNCHER
############################################
# ~/Applications is the canonical home for downloaded AppImages; create it
# unconditionally so other tooling can rely on it.
mkdir -vp ~/Applications

read -r -p "Install AppImageLauncher? [y/N]: " ans
case "${ans,,}" in
  y|yes)
    # Release asset names carry a build hash, so resolve the x86_64 AppImage
    # URL from the latest release at runtime instead of hardcoding it.
    AIL_API="https://api.github.com/repos/TheAssassin/AppImageLauncher/releases/latest"
    AIL_GREP='https://[^"]*-lite-[^"]*x86_64.AppImage'
    AIL_URL=$(curl -fsSL "$AIL_API" | grep -m1 -o "$AIL_GREP")
    if [[ -n "$AIL_URL" ]]; then
      AIL_DEST=~/Applications/AppImageLauncher.AppImage
      curl -fSL "$AIL_URL" -o "$AIL_DEST"
      chmod +x "$AIL_DEST"
      echo "Downloaded AppImageLauncher to $AIL_DEST"
      # The lite AppImage integrates itself (binfmt hook + desktop entry) via
      # its `install` subcommand; ~/.local/lib/appimagelauncher-lite marks it
      # done, so skip the step when re-running setup.sh.
      if [ -d ~/.local/lib/appimagelauncher-lite ]; then
        echo "AppImageLauncher already integrated; skipping install."
      else
        "$AIL_DEST" install
      fi
    else
      echo "Could not find AppImageLauncher AppImage asset; install manually."
    fi
    ;;
  *)
    echo "Cancelled."
    ;;
esac

############################################
# JESSEDUFFIELD TUIS (lazygit, lazydocker)
############################################
read -r -p "Install latest lazygit & lazydocker? [y/N]: " ans
case "${ans,,}" in
  y|yes)
    mkdir -vp ~/.local/bin
    # Resolve each release's x86_64 Linux tarball URL at runtime so versions
    # aren't hardcoded. grep -i because the two repos disagree on casing
    # (lazydocker uses Linux_x86_64, lazygit uses linux_x86_64).
    for tool in lazygit lazydocker; do
      api="https://api.github.com/repos/jesseduffield/$tool/releases/latest"
      url=$(curl -fsSL "$api" | grep -m1 -io 'https://[^"]*linux_x86_64.tar.gz')
      if [[ -n "$url" ]]; then
        curl -fSL "$url" -o /tmp/$tool.tar.gz
        tar -xzf /tmp/$tool.tar.gz -C ~/.local/bin "$tool"
        rm -f /tmp/$tool.tar.gz
        echo "Installed $tool to ~/.local/bin/$tool"
      else
        echo "Could not find $tool release asset; install manually."
      fi
    done
    ;;
  *)
    echo "Cancelled."
    ;;
esac

############################################
# GIT CREDENTIAL MANAGER (Azure DevOps / EPAM)
############################################
# ~/.gitconfig routes dev.azure.com through GCM (Microsoft Entra OAuth) while
# libsecret stays the default for every other host. GCM isn't in distro repos
# and ships no rpm; the x64 tarball bundles the binary with its Skia/HarfBuzz
# libs, so extract it whole under ~/.local and link the helper onto PATH. The
# libs must sit beside the binary, hence the symlink (not a copied binary).
# EPAM Azure DevOps over HTTPS only. Repo lives under git-ecosystem, not microsoft.
if ! command -v git-credential-manager &>/dev/null; then
  read -r -p "Install Git Credential Manager (Azure DevOps auth)? [y/N]: " ans
  case "${ans,,}" in
    y|yes)
      GCM_API="https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest"
      GCM_GREP='https://[^"]*gcm-linux-x64[^"]*\.tar\.gz'
      GCM_URL=$(curl -fsSL "$GCM_API" | grep -o "$GCM_GREP" | grep -v symbols | head -1)
      if [[ -n "$GCM_URL" ]]; then
        GCM_DIR=~/.local/share/git-credential-manager
        mkdir -vp "$GCM_DIR" ~/.local/bin
        curl -fSL "$GCM_URL" -o /tmp/gcm.tar.gz
        tar -xzf /tmp/gcm.tar.gz -C "$GCM_DIR"
        rm -f /tmp/gcm.tar.gz
        ln -sf "$GCM_DIR/git-credential-manager" ~/.local/bin/git-credential-manager
      else
        echo "Could not resolve GCM tarball asset; install manually."
      fi
      ;;
    *)
      echo "Skipped GCM; Azure DevOps over HTTPS will prompt until installed."
      ;;
  esac
fi

############################################
# GNOME KEYBOARD SHORTCUTS (Fedora)
############################################
# Fedora ships GNOME by default, so apply the custom gsettings keybindings.
# || true: gsettings exits non-zero on schemas missing here (e.g. dash-to-dock)
# and we don't want that to abort the rest of setup.
if [ -r /etc/os-release ] && grep -q '^ID=fedora' /etc/os-release; then
	if command -v gsettings &>/dev/null; then
		bash ~/linux-files/scripts/de/gnome/gnome_shortcut_script.sh || true
	else
		echo "gsettings not found; skipping GNOME keyboard shortcuts."
	fi
fi

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
# App-level config (~/.logseq) is machine-local; symlink the portable bits.
# Per-graph config (each graph's logseq/config.edn) is synced with the graph.
# preferences.json is volatile UI state and intentionally not linked.
mkdir -vp ~/.logseq/config
ln -sf ~/linux-files/dotfiles/logseq/.logseq/config/config.edn ~/.logseq/config/config.edn
ln -sf ~/linux-files/dotfiles/logseq/.logseq/config/plugins.edn ~/.logseq/config/plugins.edn

# VMs (disk images stay local; launch configs live in ~/DATA/IT/vm-configs)
mkdir -vp ~/vms
if [ ! -f ~/vms/AGENTS.md ]; then
	cat > ~/vms/AGENTS.md <<'EOF'
# ~/vms — local VM payloads

This directory holds large, **local-only** VM files (`.qcow2` disks, `.iso`
installers, OVMF/TPM state). It is NOT synced and is wiped by an OS reinstall.

Launch scripts / configs are version-controlled separately in
`~/DATA/IT/vm-configs/` (Syncthing-synced, survives reinstalls). Do not keep a
VM's run script only here — its canonical home is `vm-configs`. To rebuild a VM,
recreate its disk image here and copy the matching run script from
`~/DATA/IT/vm-configs/<vm>/`.
EOF
	echo "Wrote ~/vms/AGENTS.md (points VM configs at ~/DATA/IT/vm-configs)."
fi

# IT (Syncthing) + cockpit-core symlinks
if [ -d ~/DATA/IT ]; then
	ln -sfn ~/DATA/IT ~/IT
	mkdir -vp ~/IT/hyprland
	[ -d ~/DATA/cockpit-core ] && ln -sfn ~/DATA/cockpit-core ~/cockpit-core
else
	echo "WARNING: ~/DATA/IT not found — is Syncthing set up on this machine?"
	echo "Skipping ~/IT and ~/cockpit-core symlinks until DATA/IT syncs."
	read -p "Press enter to continue ... "
fi
