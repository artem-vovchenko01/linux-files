#!/usr/bin/env bash
# Opens the Wi-Fi login page when NetworkManager detects a captive portal.
# Omarchy has no portal popup, so hotspots like McD's look connected but
# carry no traffic until someone opens their login page.
set -u

# Plain HTTP on purpose: portals intercept only unencrypted requests.
PORTAL_URL=http://neverssl.com

state() { nmcli -t -f CONNECTIVITY general 2>/dev/null; }

opened=""
handle() {
	if [ "$(state)" != portal ]; then
		opened=""
		return
	fi
	[ -n "$opened" ] && return
	opened=1
	echo "portal detected, opening $PORTAL_URL"
	notify-send "Wi-Fi login needed" "Opening the hotspot login page"
	omarchy-launch-browser "$PORTAL_URL"
	# NetworkManager rechecks only every 5 minutes and keeps a big route
	# penalty on the link until then. Recheck often to clear it right
	# after the login.
	for _ in $(seq 60); do
		sleep 5
		[ "$(nmcli networking connectivity check)" = full ] && break
	done
}

handle
NM=org.freedesktop.NetworkManager
stdbuf -oL gdbus monitor --system --dest $NM --object-path /${NM//.//} |
	while read -r line; do
		case $line in
		*Connectivity*) handle ;;
		esac
	done
