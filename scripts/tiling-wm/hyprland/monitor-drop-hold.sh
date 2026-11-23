#!/usr/bin/env bash
# When an external monitor drops out while the screen is locked (the HP
# 724pu does when it sleeps), keep only the laptop panel on until the next
# unlock, then hand the session back to the external monitor. Without the
# hold, the session jumps between screens each time the monitor wakes and
# sleeps again.
set -u

HOLD="$HOME/.local/state/omarchy/toggles/hypr/external-monitor-hold.lua"
socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

locked() {
	[[ $(omarchy-shell lock isLocked 2>/dev/null) == true ]]
}

# $1 is the event payload: ID,NAME,DESCRIPTION. The rule is Lua code that
# Hyprland loads, so only plain names and descriptions go into it.
hold() {
	local name desc output
	name=$(cut -d, -f2 <<<"$1")
	desc=$(cut -d, -f3- <<<"$1")
	[[ $name =~ ^(eDP|LVDS|DSI)- ]] && return
	locked || return
	if [[ $desc =~ ^[A-Za-z0-9\ ._-]+$ ]]; then
		output="desc:$desc"
	elif [[ $name =~ ^[A-Za-z0-9._-]+$ ]]; then
		output=$name
	else
		return
	fi
	echo "$name dropped out while locked, holding the laptop panel"
	mkdir -p "$(dirname "$HOLD")"
	local rule
	rule=$(printf 'hl.monitor({ output = "%s", disabled = true })' "$output")
	grep -qxF "$rule" "$HOLD" 2>/dev/null || printf '%s\n' "$rule" >>"$HOLD"
	omarchy-hyprland-monitor-internal on >/dev/null 2>&1 || true
	hyprctl reload >/dev/null
}

release() {
	echo "unlocked, handing back to the external monitor"
	rm -f "$HOLD"
	hyprctl reload >/dev/null
	# The monitor may need a few seconds to wake and report a mode.
	local delay
	for delay in 1 2 4 8; do
		sleep "$delay"
		if omarchy-hyprland-monitor-external-active; then
			omarchy-hyprland-monitor-internal off >/dev/null 2>&1 || true
			return
		fi
	done
}

[[ -f $HOLD ]] && ! locked && release

while read -r -t 2 event || [[ $? -gt 128 ]]; do
	case "$event" in
	monitorremovedv2\>\>*) hold "${event#*>>}" ;;
	esac
	event=""
	[[ -f $HOLD ]] && ! locked && release
done < <(socat -U - "UNIX-CONNECT:$socket")
