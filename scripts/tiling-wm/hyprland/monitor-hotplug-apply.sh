#!/usr/bin/env bash
set -euo pipefail

INTERNAL_PREFERRED="eDP-1"
EXTERNAL_PREFERRED="HDMI-A-1"
INTERNAL_SCALE="1"
EXTERNAL_SCALE="1.6"

quiet=0
if [[ "${1:-}" == "--quiet" ]]; then
  quiet=1
fi

log() {
  if [[ "$quiet" -eq 0 ]]; then
    printf '[monitor-hotplug] %s\n' "$*"
  fi
}

readarray -t outputs < <(hyprctl monitors all | awk '/^Monitor / { print $2 }')

if [[ "${#outputs[@]}" -eq 0 ]]; then
  log "No outputs reported by hyprctl"
  exit 0
fi

has_output() {
  local needle="$1"
  local out
  for out in "${outputs[@]}"; do
    if [[ "$out" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

pick_internal() {
  local out

  if has_output "$INTERNAL_PREFERRED"; then
    printf '%s\n' "$INTERNAL_PREFERRED"
    return
  fi

  for out in "${outputs[@]}"; do
    if [[ "$out" =~ ^eDP ]]; then
      printf '%s\n' "$out"
      return
    fi
  done

  printf '\n'
}

pick_external() {
  local out

  if has_output "$EXTERNAL_PREFERRED"; then
    printf '%s\n' "$EXTERNAL_PREFERRED"
    return
  fi

  for out in "${outputs[@]}"; do
    if [[ ! "$out" =~ ^eDP ]]; then
      printf '%s\n' "$out"
      return
    fi
  done

  printf '\n'
}

internal_output="$(pick_internal)"
external_output="$(pick_external)"

target_output=""
if [[ -n "$external_output" ]]; then
  hyprctl keyword monitor "$external_output,preferred,auto,$EXTERNAL_SCALE" >/dev/null
  if [[ -n "$internal_output" && "$internal_output" != "$external_output" ]]; then
    hyprctl keyword monitor "$internal_output,disable" >/dev/null
  fi
  target_output="$external_output"
  log "Using external output: $external_output"
else
  if [[ -z "$internal_output" ]]; then
    log "No internal output found"
    exit 0
  fi
  hyprctl keyword monitor "$internal_output,preferred,auto,$INTERNAL_SCALE" >/dev/null
  target_output="$internal_output"
  log "Using internal output: $internal_output"
fi

for ws in 1 2 3 4 5 6 7 8 9 10; do
  hyprctl dispatch moveworkspacetomonitor "$ws $target_output" >/dev/null 2>&1 || true
done

hyprctl dispatch workspace 1 >/dev/null 2>&1 || true

if [[ "$quiet" -eq 0 ]]; then
  notify-send "Hyprland display profile" "Active output: $target_output" || true
fi
