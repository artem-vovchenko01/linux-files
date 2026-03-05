#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_SCRIPT="$SCRIPT_DIR/monitor-hotplug-apply.sh"

if [[ ! -x "$APPLY_SCRIPT" ]]; then
  echo "Missing apply script: $APPLY_SCRIPT" >&2
  exit 1
fi

"$APPLY_SCRIPT" --quiet || true

socket="${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

# Read events from the Hyprland socket; reconnect if stream drops.
while true; do
  if [[ ! -S "$socket" ]]; then
    sleep 1
    continue
  fi

  socat -u UNIX-CONNECT:"$socket" - 2>/dev/null | while IFS= read -r event; do
    case "$event" in
      monitoradded*|monitorremoved*|configreloaded*)
        "$APPLY_SCRIPT" --quiet || true
        ;;
    esac
  done || true

  sleep 2
done
