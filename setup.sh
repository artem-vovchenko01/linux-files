#!/usr/bin/env bash
set -euxo pipefail

# Safe to re-run on any distro: links are refreshed, a real file in the way
# is moved aside first, installs skip what is present, and every step that
# installs software or changes the system asks first. No answer means no.

if (( EUID == 0 )); then
	echo "Run setup.sh as your user, not root. It calls sudo where needed." >&2
	exit 1
fi
LF=~/linux-files
if [ ! -d "$LF/dotfiles" ]; then
	echo "Clone this repo to $LF first: every link points there." >&2
	exit 1
fi

DATA_DIR=/mnt/data/data

# Find tools that user-level installers put outside the default PATH.
PATH=~/.local/bin:~/.grok/bin:~/.opencode/bin:~/.npm-global/bin:$PATH

# Omarchy 4 ships as a package under /usr/share/omarchy; 3.x lived in
# ~/.local/share/omarchy. Omarchy owns its desktop, terminal and editor
# configs, so setup.sh leaves those alone there.
IS_OMARCHY=false
if [ -d /usr/share/omarchy ] || [ -d ~/.local/share/omarchy ]; then
	IS_OMARCHY=true
fi
echo "Omarchy: $IS_OMARCHY"

# ask, link, package helpers and PKG_MGR detection.
source "$LF/setup-lib.sh"

############################################
# CONFIGS
############################################

# Shell
link "$LF/dotfiles/bash/.shrc.part" ~/.shrc.part.sh
# cmds: fuzzy menu of my scripts (scripts/cmds.sources lists the folders).
link "$LF/scripts/cmds.sh" ~/.local/bin/cmds
grep -qF .shrc.part.sh ~/.bashrc || echo "source ~/.shrc.part.sh" >> ~/.bashrc

# Claude Code Router plugin (adds the OpenCode Go session header)
link "$LF/dotfiles/claude-code-router/plugins/opencode-session.js" ~/.claude-code-router/plugins/opencode-session.js

# SSH
link "$LF/dotfiles/ssh/.ssh/config" ~/.ssh/config

# Git
link "$LF/dotfiles/git/.gitconfig" ~/.gitconfig
# ~/.gitconfig includes ~/.gitconfig-work; the work setup links it.

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

# Lunarvim
link "$LF/dotfiles/lunarvim/.config/lvim/config.lua" ~/.config/lvim/config.lua

# lf
link "$LF/dotfiles/lf/.config/lf/lfrc" ~/.config/lf/lfrc

# VSCode
for app in "Code - OSS" Code Cursor; do
	link "$LF/dotfiles/code/settings.json" ~/.config/"$app"/User/settings.json
	link "$LF/dotfiles/code/keybindings.json" ~/.config/"$app"/User/keybindings.json
done

if $IS_OMARCHY; then
	echo "Omarchy: keeping its Hyprland, terminal, tmux, nvim and font configs."
	# Personal input overrides only (natural touchpad scroll).
	link "$LF/dotfiles/omarchy/hypr/input.lua" ~/.config/hypr/input.lua
	"$LF/scripts/tiling-wm/terminal-font-size.sh" 11
else
	# Hyprland desktop (Omarchy 4 has its own: Lua config + Quickshell)
	link "$LF/dotfiles/hyprland/hyprland.conf" ~/.config/hypr/hyprland.conf
	link "$LF/dotfiles/hyprland/hypridle.conf" ~/.config/hypr/hypridle.conf
	link "$LF/dotfiles/hyprland/hyprpaper.conf" ~/.config/hypr/hyprpaper.conf
	link "$LF/dotfiles/mako/.config/mako/config" ~/.config/mako/config
	link "$LF/dotfiles/dunst/dunstrc" ~/.config/dunst/dunstrc
	for f in config config-app config-wallpapers style.css; do
		link "$LF/dotfiles/wofi/.config/wofi/$f" ~/.config/wofi/$f
	done
	link "$LF/dotfiles/waybar/.config/waybar/config.jsonc" ~/.config/waybar/config.jsonc
	link "$LF/dotfiles/waybar/.config/waybar/style.css" ~/.config/waybar/style.css

	# Terminals, tmux and Neovim (Omarchy themes its own copies)
	link "$LF/dotfiles/kitty/.config/kitty/kitty.conf" ~/.config/kitty/kitty.conf
	link "$LF/dotfiles/foot/.config/foot/foot.ini" ~/.config/foot/foot.ini
	link "$LF/dotfiles/tmux/tmux.conf" ~/.tmux.conf
	link "$LF/dotfiles/nvim/.config/nvim" ~/.config/nvim
fi

# Ptyxis (Fedora default terminal): settings live in dconf, not a file, so we
# write the 10M-line scrollback into the default profile instead of symlinking.
if command -v ptyxis >/dev/null && command -v dconf >/dev/null; then
  PTYXIS_UUID=$(dconf read /org/gnome/Ptyxis/default-profile-uuid | tr -d "'" || true)
  if [ -n "$PTYXIS_UUID" ]; then
    PTYXIS_P=/org/gnome/Ptyxis/Profiles/$PTYXIS_UUID/
    dconf write "${PTYXIS_P}limit-scrollback" true
    dconf write "${PTYXIS_P}scrollback-lines" 10000000
  fi
fi

# Syncthing (config + device keys live in ~/DATA/IT, database stays local)
# config.xml is NOT symlinked: Syncthing rewrites it via atomic rename, which
# replaces a symlink with a real file. Instead we point its config dir
# (STCONFDIR) at ~/DATA/IT via a systemd drop-in and keep the database
# (STDATADIR) on local storage. On a fresh machine the identity comes from an
# encrypted restore kit: on the Ventoy stick (IT + work-resources + Secrets)
# or on Google Drive (IT only). Its passphrase is in Bitwarden.
mkdir -vp ~/DATA
if ! command -v syncthing &>/dev/null && ask "Install Syncthing now (needed to restore it)?"; then
	pkg_ensure_installed syncthing
fi
SYNCTHING_SRC=~/DATA/IT/configs/syncthing
SYNCTHING_DROPIN=$LF/systemd-units/syncthing.service.d/override.conf
RESTORE_DRIVE_URL=https://drive.google.com/drive/folders/1Z-2VjsGQuBMT91-Q921ffovOa3kB2wxV

# Ask where the restore kit is until ~/DATA/IT exists or Artem skips.
restore_syncthing_identity() {
	local choice kit
	local stick=/dev/disk/by-label/Ventoy
	while [ ! -f "$SYNCTHING_SRC/config.xml" ]; do
		echo
		echo "Syncthing identity (~/DATA/IT) is missing. Restore it from:"
		echo "  [s] the Ventoy stick (restore-kit-*.tar.gpg)"
		echo "  [d] Google Drive (download it in the browser)"
		echo "  [n] nowhere: start with a new device ID"
		read -r -p "Choice [s/d/n]: " choice </dev/tty || choice=n
		kit=""
		case "${choice,,}" in
			s)
				if [ -e "$stick" ] && ! findmnt -S "$stick" &>/dev/null; then
					udisksctl mount -b "$stick" || true
				fi
				kit=$(ls /run/media/"$USER"/*/restore-kit-*.tar.gpg 2>/dev/null | tail -1 || true)
				[ -n "$kit" ] || echo "No restore kit under /run/media/$USER. Plug in the stick."
				;;
			d)
				echo "Sign in with the ext Google account and download"
				echo "restore-kit-IT-*.tar.gpg into ~/Downloads: $RESTORE_DRIVE_URL"
				xdg-open "$RESTORE_DRIVE_URL" &>/dev/null || true
				read -r -p "Press Enter when the download has finished ... " </dev/tty || true
				kit=$(ls -t ~/Downloads/restore-kit-*.tar.gpg 2>/dev/null | head -1 || true)
				[ -n "$kit" ] || echo "No restore-kit-*.tar.gpg in ~/Downloads."
				;;
			n)
				return 1
				;;
		esac
		if [ -n "$kit" ]; then
			echo "Unpacking $kit into ~ (gpg asks for the passphrase)."
			gpg --decrypt "$kit" | tar -xf - -C ~ || echo "Unpacking failed. Wrong passphrase?"
		fi
	done
}

apply_syncthing_redirect() {
	local current
	current=$(readlink ~/.config/systemd/user/syncthing.service.d/override.conf || true)
	if [ "$current" = "$SYNCTHING_DROPIN" ]; then
		echo "Syncthing already reads its config from $SYNCTHING_SRC."
		python3 "$LF/scripts/syncthing/st-folders.py" settle
		python3 "$LF/scripts/syncthing/st-folders.py" save
		systemctl --user enable --now syncthing || true
		return
	fi
	# Don't silently shadow a different identity already in the default location.
	for d in ~/.local/state/syncthing ~/.config/syncthing; do
		if [ -f "$d/config.xml" ]; then
			echo "Existing Syncthing identity at $d would be shadowed by ~/DATA/IT."
			if ! ask "Repoint Syncthing config to ~/DATA/IT and restart?"; then
				echo "Left Syncthing untouched."
				return
			fi
			break
		fi
	done
	systemctl --user stop syncthing 2>/dev/null || true
	# Syncthing refuses missing folder paths and never syncs .stignore files.
	python3 "$LF/scripts/syncthing/st-folders.py" restore
	link "$SYNCTHING_DROPIN" ~/.config/systemd/user/syncthing.service.d/override.conf
	systemctl --user daemon-reload
	if systemctl --user enable --now syncthing; then
		echo "Syncthing config dir set to $SYNCTHING_SRC; service (re)started."
	else
		echo "WARNING: Syncthing did not start. Run:"
		echo "  systemctl --user enable --now syncthing"
	fi
}

if [ -f "$SYNCTHING_DROPIN" ]; then
	if [ -f "$SYNCTHING_SRC/config.xml" ] || restore_syncthing_identity; then
		apply_syncthing_redirect
	else
		echo "Syncthing: not restored. Re-run setup.sh to restore the identity,"
		echo "or let the peers accept a new device ID (skill syncthing-workflow)."
	fi
fi


############################################
# PACKAGES
############################################
# Common packages (same name across distros)
PACKAGES_COMMON="less git jq git-delta vifm neovim zoxide fzf direnv kitty foot imv nemo thunar tumbler ffmpegthumbnailer file-roller thunar-archive-plugin zip unzip gedit zathura tldr man-db syncthing htop btop"
# thunar-archive-plugin - for enabling archiving options in thunar
# tumbler ffmpegthumbnailer file-roller - for making thumbnails in thunar work
# tldr, not tealdeer: Omarchy ships tldr and the two conflict on Arch.

# Distro-specific packages (different names across distros)
case "$PKG_MGR" in
	pacman)
		# fuse2: type-2 AppImages link against the FUSE 2 ABI (libfuse.so.2).
		PACKAGES_DISTRO="pacman-contrib libnotify otf-font-awesome inetutils libgsf zathura-pdf-mupdf tesseract-data-eng man-pages starship fuse2"
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
echo "$PACKAGES"
if ask "Install the above packages?"; then
	pkg_install $PACKAGES
fi

############################################
# HYPRLAND PACKAGES
############################################
# Tools for the hand-made Hyprland desktop. Omarchy brings its own shell.
if ! $IS_OMARCHY; then
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
	if ask "Install Hyprland packages?"; then
		pkg_install $HYPR_PACKAGES
	fi
fi

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
if ask "Install fonts?"; then
	if [[ -n "$FONT_PACKAGES" ]]; then
		pkg_install $FONT_PACKAGES
	else
		echo "Unknown package manager — install fonts manually."
	fi
	# Nerd Font for lvim/terminal/waybar icons. pacman ships ttf-hack-nerd;
	# other distros don't package it, so fetch it into the user font dir.
	if ! fc-list | grep -qi "Hack Nerd"; then
		NERD_DIR=~/.local/share/fonts/HackNerd
		NERD_ZIP=$(mktemp)
		mkdir -vp "$NERD_DIR"
		NERD_URL=https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
		curl -fsSL "$NERD_URL" -o "$NERD_ZIP"
		unzip -o "$NERD_ZIP" -d "$NERD_DIR"
		rm -f "$NERD_ZIP"
	fi
	# omarchy-font-set rewrites ~/.config/fontconfig/fonts.conf, which would
	# write through a link into this repo.
	if ! $IS_OMARCHY; then
		link "$LF/dotfiles/fontconfig/.config/fontconfig/fonts.conf" ~/.config/fontconfig/fonts.conf
	fi
	fc-cache -fv
	fc-match sans-serif
	fc-match system-ui
	fc-match monospace
fi

############################################
# FIREWALL (ufw: Omarchy and other Arch setups)
############################################
# Omarchy blocks all incoming traffic except LocalSend. Each opening asks
# first. Fedora uses firewalld, which this script doesn't touch.
if command -v ufw &>/dev/null; then
	if ask "Firewall: allow Syncthing from private networks only (22000, 21027/udp)?"; then
		for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
			sudo ufw allow from "$net" to any port 22000 proto tcp comment syncthing
			sudo ufw allow from "$net" to any port 22000 proto udp comment syncthing
			sudo ufw allow from "$net" to any port 21027 proto udp comment syncthing-discovery
		done
	fi
	if ask "Firewall: allow all incoming on tailscale0 (VM VNC/RDP, ssh over the tailnet)?"; then
		sudo ufw allow in on tailscale0 comment tailscale
	fi
	if ask "Enable the ssh server and open 22/tcp (rate-limited)?"; then
		if command -v omarchy-setup-security-sshd &>/dev/null; then
			omarchy-setup-security-sshd
		else
			pkg_ensure_installed openssh
			sudo systemctl enable --now sshd.service
			sudo ufw limit 22/tcp comment ssh
		fi
	fi
fi

############################################
# OOM KILLER
############################################
if ask "Configure oom killer?"; then
	case "$PKG_MGR" in
		pacman|apt|dnf)
			pkg_ensure_installed earlyoom
			;;
		*)
			echo "earlyoom package installation is not configured for $PKG_MGR. Install it manually."
			;;
	esac

	if command -v systemctl &>/dev/null; then
		install_root_file "$LF/system-config/earlyoom/etc/default/earlyoom" /etc/default/earlyoom
		install_root_file "$LF/system-config/earlyoom/etc/systemd/system/earlyoom.service.d/override.conf" /etc/systemd/system/earlyoom.service.d/override.conf
		sudo systemctl daemon-reload
		sudo systemctl enable --now earlyoom
		sudo systemctl restart earlyoom
	else
		echo "systemctl not found; skipping service activation."
	fi
fi

############################################
# APPIMAGELAUNCHER
############################################
# ~/Applications is the canonical home for downloaded AppImages; create it
# unconditionally so other tooling can rely on it.
mkdir -vp ~/Applications

if ask "Install AppImageLauncher?"; then
	AIL_DEST=~/Applications/AppImageLauncher.AppImage
	if [ ! -e "$AIL_DEST" ]; then
		# Release asset names carry a build hash, so resolve the x86_64 AppImage
		# URL from the latest release at runtime instead of hardcoding it.
		AIL_API="https://api.github.com/repos/TheAssassin/AppImageLauncher/releases/latest"
		AIL_GREP='https://[^"]*-lite-[^"]*x86_64.AppImage'
		AIL_URL=$(curl -fsSL "$AIL_API" | grep -m1 -o "$AIL_GREP" || true)
		if [[ -n "$AIL_URL" ]]; then
			curl -fSL "$AIL_URL" -o "$AIL_DEST"
			chmod +x "$AIL_DEST"
			echo "Downloaded AppImageLauncher to $AIL_DEST"
		else
			echo "Could not find AppImageLauncher AppImage asset; install manually."
		fi
	fi
	# The lite AppImage integrates itself (binfmt hook + desktop entry) via
	# its `install` subcommand; ~/.local/lib/appimagelauncher-lite marks it
	# done, so skip the step when re-running setup.sh.
	if [ -d ~/.local/lib/appimagelauncher-lite ]; then
		echo "AppImageLauncher already integrated; skipping install."
	elif [ -x "$AIL_DEST" ]; then
		"$AIL_DEST" install
	fi
fi

############################################
# JESSEDUFFIELD TUIS (lazygit, lazydocker)
############################################
if ask "Install latest lazygit & lazydocker?"; then
	if [ "$PKG_MGR" = pacman ]; then
		pkg_ensure_installed lazygit lazydocker
	else
		mkdir -vp ~/.local/bin
		# Resolve each release's x86_64 Linux tarball URL at runtime so versions
		# aren't hardcoded. grep -i because the two repos disagree on casing
		# (lazydocker uses Linux_x86_64, lazygit uses linux_x86_64).
		for tool in lazygit lazydocker; do
			api="https://api.github.com/repos/jesseduffield/$tool/releases/latest"
			url=$(curl -fsSL "$api" | grep -m1 -io 'https://[^"]*linux_x86_64.tar.gz' || true)
			if [[ -n "$url" ]]; then
				tarball=$(mktemp)
				curl -fSL "$url" -o "$tarball"
				tar -xzf "$tarball" -C ~/.local/bin "$tool"
				rm -f "$tarball"
				echo "Installed $tool to ~/.local/bin/$tool"
			else
				echo "Could not find $tool release asset; install manually."
			fi
		done
	fi
fi

############################################
# DESKTOP APPS
############################################
# Google Chrome also runs the shared EPAM profile (epam-chrome.service).
if ! command -v google-chrome-stable &>/dev/null && ask "Install Google Chrome?"; then
	case "$PKG_MGR" in
		pacman)
			aur_ensure_installed google-chrome
			;;
		dnf)
			# Fedora ships the repo file disabled in fedora-workstation-repositories.
			pkg_ensure_installed fedora-workstation-repositories
			sudo dnf config-manager setopt google-chrome.enabled=1
			pkg_ensure_installed google-chrome-stable
			;;
		*)
			echo "Install Chrome from https://www.google.com/chrome/"
			;;
	esac
fi

if ask "Install OnlyOffice and OBS Studio?"; then
	case "$PKG_MGR" in
		pacman)
			aur_ensure_installed onlyoffice-bin
			pkg_ensure_installed obs-studio
			;;
		dnf)
			if ! pkg_is_installed onlyoffice-repo; then
				pkg_install https://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm
			fi
			pkg_ensure_installed onlyoffice-desktopeditors obs-studio
			;;
		*)
			pkg_ensure_installed obs-studio
			echo "Install OnlyOffice from https://www.onlyoffice.com/download-desktop.aspx"
			;;
	esac
fi

# Editors and apps that come as AppImages outside Arch.
if ! have_app cursor Cursor; then
	if ask "Install Cursor?"; then
		if [ "$PKG_MGR" = pacman ]; then
			aur_ensure_installed cursor-bin
		else
			# Cursor's stable channel redirects to the current AppImage.
			fetch_appimage https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/latest Cursor
		fi
	fi
fi

# Omarchy ships Obsidian and LocalSend.
if ! have_app obsidian Obsidian || ! have_app localsend LocalSend; then
	if ask "Install Obsidian and LocalSend?"; then
		if [ "$PKG_MGR" = pacman ]; then
			pkg_ensure_installed obsidian
			aur_ensure_installed localsend-bin
		else
			OBS_API=https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest
			LS_API=https://api.github.com/repos/localsend/localsend/releases/latest
			OBS_URL=$(curl -fsSL "$OBS_API" | grep -o 'https://[^"]*/Obsidian-[0-9.]*\.AppImage' | head -1 || true)
			LS_URL=$(curl -fsSL "$LS_API" | grep -o 'https://[^"]*linux-x86-64\.AppImage' | head -1 || true)
			if [ -n "$OBS_URL" ]; then
				fetch_appimage "$OBS_URL" Obsidian
			fi
			if [ -n "$LS_URL" ]; then
				fetch_appimage "$LS_URL" LocalSend
			fi
		fi
	fi
fi

############################################
# WORK AND CLOUD TOOLS
############################################
if ask "Install DevOps CLIs (terraform, cosign, trivy, rclone, freerdp)?"; then
	case "$PKG_MGR" in
		pacman)
			pkg_ensure_installed terraform cosign trivy rclone freerdp
			;;
		dnf)
			pkg_ensure_installed trivy rclone freerdp
			if ! command -v terraform &>/dev/null; then
				if [ ! -f /etc/yum.repos.d/hashicorp.repo ]; then
					sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
				fi
				pkg_ensure_installed terraform
			fi
			if ! command -v cosign &>/dev/null; then
				mkdir -vp ~/.local/bin
				curl -fSL https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 -o ~/.local/bin/cosign
				chmod +x ~/.local/bin/cosign
			fi
			;;
		*)
			pkg_ensure_installed trivy rclone freerdp
			echo "Install terraform and cosign by hand on $PKG_MGR."
			;;
	esac
fi

# Google Drive remotes: gdrive = main Google account, gdrive-ext = ext account.
# Both use Artem's own OAuth client from ~/DATA/Secrets (the public
# repo holds no secret). Each remote opens a browser once: sign in with the
# account named in the prompt. Tokens stay in ~/.config/rclone/rclone.conf.
RCLONE_CLIENT=~/DATA/Secrets/rclone/rclone-gdrive-oauth-client.json
if command -v rclone &>/dev/null && [ -f "$RCLONE_CLIENT" ]; then
	for remote_account in gdrive:main gdrive-ext:ext; do
		remote=${remote_account%%:*}
		account=${remote_account#*:}
		if rclone listremotes | grep -qx "$remote:"; then
			echo "rclone remote $remote: already configured."
		elif ask "Connect rclone remote $remote (browser sign-in, $account Google account)?"; then
			# No xtrace here: it would print the client secret.
			{ set +x; } 2>/dev/null
			rclone config create "$remote" drive scope=drive \
				client_id="$(jq -r .installed.client_id "$RCLONE_CLIENT")" \
				client_secret="$(jq -r .installed.client_secret "$RCLONE_CLIENT")"
			set -x
		fi
	done
fi

############################################
# TAILSCALE, OLLAMA, ANDROID
############################################
if ! command -v tailscale &>/dev/null && ask "Install Tailscale?"; then
	if command -v omarchy-install-service-tailscale &>/dev/null; then
		# Also adds the bar panel, Taildrop receiving and `tailscale up`.
		omarchy-install-service-tailscale
	else
		run_installer https://tailscale.com/install.sh sh
		sudo systemctl enable --now tailscaled
		echo "Join the tailnet: sudo tailscale up"
	fi
fi

if ! command -v ollama &>/dev/null && ask "Install Ollama?"; then
	if [ "$PKG_MGR" = pacman ]; then
		pkg_ensure_installed ollama
		sudo systemctl enable --now ollama.service
	else
		# The official script installs the binary and an ollama.service.
		run_installer https://ollama.com/install.sh sh
	fi
fi

if ask "Install Android tools (adb, MTP, Android Studio)?"; then
	case "$PKG_MGR" in
		pacman)
			pkg_ensure_installed android-tools libmtp
			aur_ensure_installed android-studio
			;;
		dnf)
			pkg_ensure_installed android-tools libmtp-examples
			;;
		*)
			pkg_ensure_installed android-tools
			;;
	esac
	if [ "$PKG_MGR" != pacman ] && ! command -v android-studio &>/dev/null; then
		if command -v flatpak &>/dev/null; then
			flatpak install -y flathub com.google.AndroidStudio
		else
			echo "Install Android Studio from https://developer.android.com/studio"
		fi
	fi
fi

############################################
# GNOME KEYBOARD SHORTCUTS
############################################
# || true: gsettings exits non-zero on schemas missing here (e.g. dash-to-dock)
# and we don't want that to abort the rest of setup.
if command -v gnome-shell &>/dev/null && command -v gsettings &>/dev/null; then
	bash "$LF/scripts/de/gnome/gnome_shortcut_script.sh" || true
fi

############################################
# SETUP FOLDERS
############################################

# Local git backup remotes
# Bare repos live in the Syncthing folder ~/DATA/local-git.
# ~/g/<name>.git is a short alias so Cursor titles stay readable.
# A Logseq or GitHub clone often has only origin and drops remote `local`.
# Full attach-when-no-.git steps: ~/DATA/local-git/README.md
LOCAL_GIT=~/DATA/local-git
mkdir -vp ~/g
if [ -d "$LOCAL_GIT" ]; then
	for name in cockpit-core obsidian-personal obsidian-work; do
		if [ -d "$LOCAL_GIT/$name.git" ]; then
			ln -sfn "$LOCAL_GIT/$name.git" "$HOME/g/$name.git"
		fi
	done
else
	echo "WARNING: $LOCAL_GIT not found — skip ~/g aliases until it syncs."
fi

ensure_local_git_remote() {
	local repo=$1
	local name=$2
	local url="$HOME/g/$name.git"
	if [ ! -d "$repo/.git" ]; then
		return 0
	fi
	if [ ! -e "$url" ]; then
		return 0
	fi
	if git -C "$repo" remote get-url local >/dev/null 2>&1; then
		git -C "$repo" remote set-url local "$url"
	else
		git -C "$repo" remote add local "$url"
	fi
}

ensure_local_git_remote ~/DATA/cockpit-core cockpit-core
ensure_local_git_remote ~/obsidian/obsidian-personal obsidian-personal
ensure_local_git_remote ~/obsidian/obsidian-work obsidian-work

# Playground
mkdir -p ~/Playground
#if [ -d $DATA_DIR ]; then
#  ln -sf $DATA_DIR/Playground ~/Playground/shared
#fi

# Obsidian: the vaults (~/obsidian/obsidian-personal, ~/obsidian/obsidian-work)
# arrive through Syncthing.
mkdir -vp ~/obsidian

# IT (Syncthing) + cockpit-core symlinks
if [ -d ~/DATA/IT ]; then
	ln -sfn ~/DATA/IT ~/IT
	mkdir -vp ~/IT/hyprland
	[ -d ~/DATA/cockpit-core ] && ln -sfn ~/DATA/cockpit-core ~/cockpit-core
else
	echo "WARNING: ~/DATA/IT not found — is Syncthing set up on this machine?"
	echo "Skipping ~/IT and ~/cockpit-core symlinks until DATA/IT syncs."
	if [ -t 0 ]; then
		read -r -p "Press enter to continue ... " || true
	fi
fi

############################################
# USER SERVICES
############################################
WORK_HUB=~/obsidian/obsidian-work
COCKPIT_CORE=~/cockpit-core
if [ ! -d "$COCKPIT_CORE" ] && [ -d ~/DATA/cockpit-core ]; then
	COCKPIT_CORE=~/DATA/cockpit-core
fi
USER_UNITS=~/.config/systemd/user

# lid-no-suspend.service holds a logind lid-switch inhibitor;
# scripts/devices/laptop/toggle-lid-sleep.sh starts and stops it.
link "$LF/systemd-units/lid-no-suspend.service" "$USER_UNITS/lid-no-suspend.service"

# No user bus (e.g. a bare ssh login) is not a reason to abort.
systemctl --user daemon-reload || true

# The timer accepts proven Grok Bot boxes into Syncthing. Its installer
# creates any pairing secret it can't find, so run it only after the hubs
# have synced, or the boxes' secrets won't match.
STW_INSTALL=$COCKPIT_CORE/skills/syncthing-workflow/scripts/install-laptop.sh
if [ -f "$STW_INSTALL" ]; then
	echo "syncthing-workflow: run only after cockpit-core and obsidian-work synced."
	if ask "Install the syncthing-workflow timer?"; then
		bash "$STW_INSTALL"
	fi
fi

############################################
# SETUP AI CONFIGURATIONS
############################################

AI_GLOBAL=$LF/ai/CLAUDE_GLOBAL_CONFIG.md
WORK_SKILLS=$WORK_HUB/.agents/skills
PERSONAL_SKILLS=$COCKPIT_CORE/skills

# Node from mise (Omarchy's runtime manager). npm globals go to
# ~/.npm-global, which .shrc.part puts on PATH.
NPM_GLOBALS="@bitwarden/cli @codemieai/code @earendil-works/pi-coding-agent"
# opencode-session.js targets claude-code-router 2.x.
NPM_GLOBALS="$NPM_GLOBALS @musistudio/claude-code-router@2"
if ask "Install Node (mise) and npm tools (bw, codemie, pi, ccr)?"; then
	if ! command -v mise &>/dev/null; then
		if [ "$PKG_MGR" = pacman ]; then
			pkg_ensure_installed mise
		else
			run_installer https://mise.run sh
		fi
	fi
	mise use -g node@lts
	mise exec -- npm config set prefix ~/.npm-global
	mise exec -- npm install -g $NPM_GLOBALS
fi

# Agent CLIs: each vendor's own installer, run only when the tool is
# missing. They update themselves afterwards.
if ask "Install agent CLIs (claude, codex, grok, opencode, cursor-agent, agy)?"; then
	command -v claude &>/dev/null || run_installer https://claude.ai/install.sh bash
	command -v codex &>/dev/null || CODEX_NON_INTERACTIVE=1 run_installer https://chatgpt.com/codex/install.sh sh
	command -v grok &>/dev/null || run_installer https://x.ai/cli/install.sh bash
	command -v opencode &>/dev/null || run_installer https://opencode.ai/install bash
	command -v cursor-agent &>/dev/null || run_installer https://cursor.com/install bash
	command -v agy &>/dev/null || run_installer https://antigravity.google/cli/install.sh bash
fi

# The agy CLI above is separate from the Antigravity GUI apps below.
# Grok Bot desktop: x.ai serves the AppImage only through its page, so the
# browser downloads it and setup.sh moves it into ~/Applications.
# A pasted download link (right-click the button, Copy link) is used as is.
if ! have_app grok-bot GrokBot && ask "Install Grok Bot (download the AppImage from x.ai/bot)?"; then
	xdg-open https://x.ai/bot &>/dev/null || echo "Open https://x.ai/bot"
	echo "Paste the AppImage download link, or download it to ~/Downloads"
	read -r -p "and press Enter: " gb_url </dev/tty || gb_url=""
	gb=""
	if [ -n "$gb_url" ]; then
		gb=$(mktemp --suffix=.AppImage)
		curl -fSL "$gb_url" -o "$gb" || gb=""
	else
		gb=$(ls -t ~/Downloads/*[Gg]rok*.AppImage 2>/dev/null | head -1 || true)
	fi
	if [ -n "$gb" ]; then
		mkdir -p ~/Applications
		install -m 755 "$gb" ~/Applications/GrokBot.AppImage
		rm -f "$gb"
		echo "Grok Bot: ~/Applications/GrokBot.AppImage"
	else
		echo "No Grok Bot AppImage found; re-run setup.sh after downloading."
	fi
fi

if [ "$PKG_MGR" = pacman ] && ask "Install Antigravity and Antigravity IDE (AUR)?"; then
	aur_ensure_installed antigravity antigravity-ide
fi

if ask "Install extra agent tools (herdr, t3, muse, Claude Desktop)?"; then
	command -v herdr &>/dev/null || run_installer https://herdr.dev/install.sh sh
	command -v t3 &>/dev/null || run_installer https://t3.codes/install.sh sh
	# The muse launcher is the command itself; it fetches the binary on first run.
	if ! command -v muse &>/dev/null; then
		mkdir -vp ~/.local/bin
		curl -fsSL https://api.meta.ai/muse-launcher.sh -o ~/.local/bin/muse
		chmod +x ~/.local/bin/muse
	fi
	if ! command -v claude-desktop &>/dev/null; then
		case "$PKG_MGR" in
			pacman) aur_ensure_installed claude-desktop ;;
			*) echo "Claude Desktop: https://support.claude.com/en/articles/10065433-install-claude-desktop" ;;
		esac
	fi
fi

# OpenCode
link "$LF/dotfiles/opencode/opencode.json" ~/.config/opencode/opencode.json

# Portable agent preferences. Auth, sessions, and Codex config.toml stay
# in $HOME.
link "$LF/dotfiles/claude/settings.json" ~/.claude/settings.json
link "$LF/dotfiles/claude-alt/settings.json" ~/.claude-alt/settings.json
link "$LF/dotfiles/grok/config.toml" ~/.grok/config.toml
link "$LF/dotfiles/grok-alt/config.toml" ~/.grok-alt/config.toml
link "$LF/dotfiles/pi/settings.json" ~/.pi/agent/settings.json

# Shared global instructions
for home in ~/.claude ~/.claude-alt; do
	[ -d "$home" ] && link "$AI_GLOBAL" "$home/CLAUDE.md"
done
for home in ~/.codex ~/.codex-alt ~/.opencode; do
	[ -d "$home" ] && link "$AI_GLOBAL" "$home/AGENTS.md"
done

# Link every valid hub skill into an agent's global skills directory.
# Usage: link_skill_dir HUB_SKILLS_DIR AGENT_SKILLS_DIR
link_skill_dir() {
	local source_dir=$1
	local target_dir=$2
	local skill target source_real target_real
	if [ ! -d "$source_dir" ]; then
		return 0
	fi
	mkdir -p "$target_dir"
	for skill in "$source_dir"/*/; do
		[ -f "$skill/SKILL.md" ] || continue
		target="$target_dir/$(basename "$skill")"
		# Keep agent-owned directories intact.
		if [ -e "$target" ] && [ ! -L "$target" ]; then
			echo "Skipping $target: it is not a symlink."
			continue
		fi
		if [ -L "$target" ]; then
			source_real=$(readlink -f "${skill%/}")
			target_real=$(readlink -f "$target")
			# A flat namespace cannot hold two skills with the same name.
			if [ "$source_real" != "$target_real" ]; then
				echo "Skipping duplicate skill: $(basename "$skill")"
				continue
			fi
		fi
		ln -sfn "${skill%/}" "$target"
	done
}

# Hermes also uses one global skill namespace.
if [ -d ~/.hermes ]; then
	link_skill_dir "$WORK_SKILLS" ~/.hermes/skills
	link_skill_dir "$PERSONAL_SKILLS" ~/.hermes/skills
fi

# Agent sessions and memories live in the Syncthing folder
# ~/DATA/agentic-context. Its own script links every agent home into it and
# merges whatever a home already recorded.
AGENTIC_CONTEXT=~/DATA/agentic-context
if [ -x "$AGENTIC_CONTEXT/link-contexts.sh" ]; then
	"$AGENTIC_CONTEXT/link-contexts.sh"
else
	echo "$AGENTIC_CONTEXT not synced yet: accept the agentic-context folder"
	echo "in Syncthing, then re-run setup.sh."
fi

# Browser bookmarks: copies live in ~/DATA/IT/browser-bookmarks
# (bookmarks.py save). Firefox needs a profile first: start it once.
BOOKMARKS_STORE=~/DATA/IT/browser-bookmarks
if [ -d "$BOOKMARKS_STORE" ] && ask "Restore browser bookmarks (close Chromium and Firefox first)?"; then
	python3 "$LF/scripts/browser/bookmarks.py" restore || true
fi

############################################
# SETUP WORK CONFIGURATIONS
############################################
# EPAM: repos, logins (az, ADO, gcloud, Databricks, AWS), VPN, VMs and the
# hub services. It lives in the work hub, so it runs once that has synced.
WORK_SETUP=~/obsidian/obsidian-work/.ai/setup.sh
if [ -f "$WORK_SETUP" ]; then
	if ask "Setup work configurations (EPAM)?"; then
		bash "$WORK_SETUP"
	fi
else
	echo "Work setup: $WORK_SETUP not synced yet; re-run setup.sh later."
fi

echo "Manual steps: log in to each agent CLI; sudo tailscale up (outside Omarchy)."
