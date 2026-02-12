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

if command -v socat >/dev/null 2>&1 && [[ -S "$socket" ]]; then
  socat -U - UNIX-CONNECT:"$socket" | while IFS= read -r event; do
    case "$event" in
      monitoradded*|monitorremoved*)
        "$APPLY_SCRIPT" --quiet || true
        ;;
    esac
  done
  exit 0
fi

# Fallback: lightweight polling if socket events are unavailable.
last=""
while true; do
  now="$(hyprctl monitors all | awk '/^Monitor / { print $2 }' | sort | tr '\n' ' ')"
  if [[ "$now" != "$last" ]]; then
    "$APPLY_SCRIPT" --quiet || true
    last="$now"
  fi
  sleep 2
done
