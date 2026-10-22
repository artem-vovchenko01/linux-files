#!/usr/bin/env bash
set -euo pipefail

# First step on a fresh machine. Installs git, gpg and the Claude CLI and
# clones this repo. setup.sh then restores Syncthing from the restore kit,
# and an agent continues from NEW-MACHINE.md.
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

echo
echo "Next: ~/linux-files/setup.sh (asks for the restore kit: stick or Drive)."
echo "Then: cd ~/linux-files && claude"
echo "Log in, then say: continue the new machine setup from NEW-MACHINE.md"
