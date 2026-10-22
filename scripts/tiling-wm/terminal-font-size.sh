#!/usr/bin/env bash
# menu: Set the font size of Omarchy's terminals (foot, alacritty, ghostty, kitty)
#
# terminal-font-size.sh [SIZE]   default 11
#
# Edits Omarchy's own configs in place: Omarchy owns them, and
# `omarchy font set` rewrites them with sed, which would break a symlink.
# That command also resets foot to size 9, so run this again after it.
set -euo pipefail

SIZE=${1:-11}

foot=~/.config/foot/foot.ini
[ -f "$foot" ] && sed -i -E "s/^(font=[^:]*):size=[0-9.]+/\1:size=$SIZE/" "$foot"

alacritty=~/.config/alacritty/alacritty.toml
[ -f "$alacritty" ] && sed -i -E "s/^size = [0-9.]+/size = $SIZE/" "$alacritty"

ghostty=~/.config/ghostty/config
if [ -f "$ghostty" ]; then
	sed -i -E "s/^font-size = [0-9.]+/font-size = $SIZE/" "$ghostty"
	pkill -SIGUSR2 ghostty || true
fi

kitty=~/.config/kitty/kitty.conf
if [ -f "$kitty" ]; then
	if grep -qE '^font_size ' "$kitty"; then
		sed -i -E "s/^font_size .*/font_size $SIZE/" "$kitty"
	else
		printf '\nfont_size %s\n' "$SIZE" >>"$kitty"
	fi
	pkill -USR1 kitty || true
fi

echo "Terminal font size: $SIZE (foot applies it to new windows)."
