#!/usr/bin/env bash
set -euo pipefail

# First step on a fresh machine. Installs git, gpg and the Claude CLI,
# clones this repo, and unpacks the encrypted restore kit into ~/DATA.
# Then an agent continues from NEW-MACHINE.md.
#
#   git clone https://github.com/artem-vovchenko01/linux-files ~/linux-files
#   ~/linux-files/bootstrap.sh

if (( EUID == 0 )); then
	echo "Run bootstrap.sh as your user, not root." >&2
	exit 1
fi
LF=~/linux-files
REPO=https://github.com/artem-vovchenko01/linux-files.git

missing=()
for cmd in git gpg curl; do
	command -v "$cmd" &>/dev/null || missing+=("$cmd")
done
if (( ${#missing[@]} > 0 )); then
	if command -v pacman &>/dev/null; then
		sudo pacman -S --needed git gnupg curl
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y git gnupg2 curl
	elif command -v apt &>/dev/null; then
		sudo apt update && sudo apt install -y git gnupg curl
	else
		echo "Install by hand: ${missing[*]}" >&2
		exit 1
	fi
fi

[ -d "$LF/.git" ] || git clone "$REPO" "$LF"

# Download the whole installer before it runs, never a truncated one.
if ! command -v claude &>/dev/null && [ ! -x ~/.local/bin/claude ]; then
	installer=$(mktemp)
	curl -fsSL https://claude.ai/install.sh -o "$installer"
	bash "$installer"
	rm -f "$installer"
fi

# The kit holds ~/DATA/IT (Syncthing identity, SSH creds),
# ~/DATA/work-resources and ~/DATA/Private_data. Its passphrase is in
# Bitwarden. Set RESTORE_KIT=/path/to/kit when the stick is not under
# /run/media (mount it with `udisksctl mount -b /dev/sdX1`).
kit=${RESTORE_KIT:-}
if [ -z "$kit" ]; then
	kit=$(ls /run/media/"$USER"/*/restore-kit-*.tar.gpg 2>/dev/null | tail -1 || true)
fi
if [ -d ~/DATA/IT ]; then
	echo "~/DATA/IT exists: restore kit not unpacked."
elif [ -n "$kit" ] && [ -f "$kit" ]; then
	echo "Unpacking $kit into ~/DATA (gpg asks for the passphrase)."
	mkdir -p ~/DATA
	gpg --decrypt "$kit" | tar -xf - -C ~
else
	echo "No restore kit found. Syncthing will start with a new identity"
	echo "unless you set RESTORE_KIT and run bootstrap.sh again."
fi

PATH=~/.local/bin:$PATH
echo
echo "Next: cd ~/linux-files && claude"
echo "Log in, then say: continue the new machine setup from NEW-MACHINE.md"
