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

readarray -t outputs_all < <(hyprctl monitors all | awk '/^Monitor / { print $2 }')
active_outputs=()

refresh_active_outputs() {
  readarray -t active_outputs < <(hyprctl monitors | awk '/^Monitor / { print $2 }')
}

refresh_active_outputs

if [[ "${#outputs_all[@]}" -eq 0 ]]; then
  log "No outputs reported by hyprctl"
  exit 0
fi

has_output() {
  local needle="$1"
  local out
  for out in "${outputs_all[@]}"; do
    if [[ "$out" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

has_active_output() {
  local needle="$1"
  local out
  for out in "${active_outputs[@]}"; do
    if [[ "$out" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

wait_for_output_state() {
  local output="$1"
  local should_be_active="$2"
  local is_active=0
  local attempt

  for attempt in 1 2 3 4 5 6 7 8; do
    refresh_active_outputs
    if has_active_output "$output"; then
      is_active=1
    else
      is_active=0
    fi

    if [[ "$is_active" -eq "$should_be_active" ]]; then
      return 0
    fi

    sleep 0.2
  done

  return 1
}

pick_internal() {
  local out

  if has_active_output "$INTERNAL_PREFERRED"; then
    printf '%s\n' "$INTERNAL_PREFERRED"
    return
  fi

  for out in "${active_outputs[@]}"; do
    if [[ "$out" =~ ^eDP ]]; then
      printf '%s\n' "$out"
      return
    fi
  done

  if has_output "$INTERNAL_PREFERRED"; then
    printf '%s\n' "$INTERNAL_PREFERRED"
    return
  fi

  for out in "${outputs_all[@]}"; do
    if [[ "$out" =~ ^eDP ]]; then
      printf '%s\n' "$out"
      return
    fi
  done

  printf '\n'
}

pick_external() {
  local out

  if has_active_output "$EXTERNAL_PREFERRED"; then
    printf '%s\n' "$EXTERNAL_PREFERRED"
    return
  fi

  for out in "${active_outputs[@]}"; do
    if [[ ! "$out" =~ ^eDP ]]; then
      printf '%s\n' "$out"
      return
    fi
  done

  if has_output "$EXTERNAL_PREFERRED"; then
    printf '%s\n' "$EXTERNAL_PREFERRED"
    return
  fi

  for out in "${outputs_all[@]}"; do
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
  if hyprctl keyword monitor "$external_output,preferred,auto,$EXTERNAL_SCALE" >/dev/null 2>&1; then
    if wait_for_output_state "$external_output" 1; then
      if [[ -n "$internal_output" && "$internal_output" != "$external_output" ]]; then
        hyprctl keyword monitor "$internal_output,disable" >/dev/null 2>&1 || true
      fi
      target_output="$external_output"
      log "Using external output: $external_output"
    else
      log "External output not active after apply: $external_output"
    fi
  else
    log "Failed to apply external output: $external_output"
  fi
fi

if [[ -z "$target_output" ]]; then
  if [[ -z "$internal_output" ]]; then
    log "No internal output found"
    exit 0
  fi

  if ! hyprctl keyword monitor "$internal_output,preferred,auto,$INTERNAL_SCALE" >/dev/null 2>&1; then
    log "Failed to apply internal output: $internal_output"
    exit 0
  fi
  wait_for_output_state "$internal_output" 1 || refresh_active_outputs

  if has_active_output "$internal_output"; then
    target_output="$internal_output"
    log "Using internal output: $internal_output"
  elif [[ "${#active_outputs[@]}" -gt 0 ]]; then
    target_output="${active_outputs[0]}"
    log "Internal output inactive; using active output: $target_output"
  else
    target_output="$internal_output"
    log "No active outputs reported; keeping internal target: $internal_output"
  fi
fi

for ws in 1 2 3 4 5 6 7 8 9 10; do
  hyprctl dispatch moveworkspacetomonitor "$ws $target_output" >/dev/null 2>&1 || true
done

hyprctl dispatch workspace 1 >/dev/null 2>&1 || true

if [[ "$quiet" -eq 0 ]]; then
  notify-send "Hyprland display profile" "Active output: $target_output" || true
fi
