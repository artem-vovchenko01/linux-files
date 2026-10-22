#!/usr/bin/env bash
# Helpers shared by setup.sh and the work hub setup
# (~/obsidian/obsidian-work/.ai/setup.sh). Source it; it runs nothing
# except package manager detection.

############################################
# HELPERS
############################################

# ask QUESTION: true on y/yes. Without a terminal the answer is no.
ask() {
	local ans=""
	if [ -t 0 ]; then
		read -r -p "$1 [y/N]: " ans || true
	fi
	case "${ans,,}" in
		y|yes) return 0 ;;
		*) return 1 ;;
	esac
}

# link SRC DEST: point DEST at SRC. A real file or directory at DEST is
# renamed to DEST.bak-<time> first. A missing SRC leaves DEST alone, so a
# partial sync can't leave a dangling link.
link() {
	local src=$1
	local dest=$2
	if [ ! -e "$src" ]; then
		echo "Missing $src; leaving $dest unchanged."
		return 0
	fi
	mkdir -p "$(dirname "$dest")"
	if [ -e "$dest" ] && [ ! -L "$dest" ]; then
		mv -v "$dest" "$dest.bak-$(date +%Y%m%d%H%M%S)"
	fi
	ln -sfn "$src" "$dest"
}

# run_installer URL [INTERPRETER] [ARGS...]: run a vendor's install script.
# The whole script is downloaded before it runs, never a truncated one.
run_installer() {
	local url=$1
	local interp=${2:-bash}
	local tmp
	tmp=$(mktemp)
	curl -fsSL "$url" -o "$tmp"
	"$interp" "$tmp" "${@:3}"
	rm -f "$tmp"
}

# have_app CMD NAME: CMD is on PATH or ~/Applications holds a NAME*.AppImage.
have_app() {
	command -v "$1" &>/dev/null || compgen -G ~/Applications/"$2"'*.AppImage' >/dev/null
}

# fetch_appimage URL NAME: download to ~/Applications/NAME.AppImage once.
fetch_appimage() {
	local dest=~/Applications/$2.AppImage
	if have_app "$2" "$2"; then
		echo "Already present: $2"
		return 0
	fi
	mkdir -p ~/Applications
	curl -fSL "$1" -o "$dest.part"
	chmod +x "$dest.part"
	mv "$dest.part" "$dest"
}

############################################
# PACKAGE MANAGER DETECTION
############################################
if command -v pacman &>/dev/null; then
	PKG_MGR=pacman
	# Plain -S with --needed, like Omarchy's own pkg-add: -Sy without -u
	# risks a partial upgrade. Names the repos don't know are skipped, the
	# same as dnf --skip-unavailable.
	pkg_install() {
		local pkg
		local known=()
		for pkg in "$@"; do
			if pacman -Si "$pkg" &>/dev/null; then
				known+=("$pkg")
			else
				echo "Not in the repos, skipped: $pkg"
			fi
		done
		if (( ${#known[@]} > 0 )); then
			sudo pacman -S --needed "${known[@]}"
		fi
	}
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

# AUR packages go through yay, which Omarchy ships.
aur_ensure_installed() {
	local missing=()
	local pkg
	if ! command -v yay &>/dev/null; then
		echo "yay not found. Install from the AUR by hand: $*"
		return 0
	fi
	for pkg in "$@"; do
		pkg_is_installed "$pkg" || missing+=("$pkg")
	done
	if (( ${#missing[@]} > 0 )); then
		yay -S --needed "${missing[@]}"
	fi
}

install_root_file() {
	local src="$1"
	local dst="$2"
	local mode="${3:-0644}"

	sudo install -D -m "$mode" "$src" "$dst"
}
