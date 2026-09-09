#!/usr/bin/env bash

set -euo pipefail

VPN_SERVER_FILE="$HOME/.work-vpn-server"
if [ ! -r "$VPN_SERVER_FILE" ]; then
	echo "anomaly: $VPN_SERVER_FILE missing" >&2
	exit 1
fi
VPN_SERVER=$(head -n 1 "$VPN_SERVER_FILE")
if [ -z "$VPN_SERVER" ]; then
	echo "anomaly: $VPN_SERVER_FILE is empty" >&2
	exit 1
fi

sudo gpclient connect "$VPN_SERVER" --browser
