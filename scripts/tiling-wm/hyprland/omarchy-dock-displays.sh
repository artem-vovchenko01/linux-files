#!/usr/bin/env bash
# menu: Omarchy: use only the external monitor while one is plugged in
#
# Started once per session from ~/.config/hypr/monitors.lua. With an
# external monitor connected the laptop panel is off; without one it is on.
#
# The cable state comes from the kernel, not from Hyprland. With the laptop
# panel off, unplugging the last monitor makes Hyprland add a virtual
# FALLBACK output, and omarchy-hyprland-monitor-external-active takes that
# for an external monitor, so Omarchy's own watcher never turns the panel on.
set -euo pipefail

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/omarchy-dock-displays.lock"
flock -n 9 || exit 0

external_cable() {
  local status name
  for status in /sys/class/drm/card*-*/status; do
    name=${status%/status}
    name=${name##*/}
    name=${name#card*-}
    [[ $name =~ ^(eDP|LVDS|DSI)- ]] && continue
    [[ $(<"$status") == connected ]] && return 0
  done
  return 1
}

apply() {
  if external_cable; then
    # The new monitor may not be enabled yet; a later retry catches it.
    omarchy-hyprland-monitor-external-active || return 0
    omarchy-hyprland-toggle-enabled internal-monitor-disable && return 0
    omarchy-hyprland-monitor-internal off >/dev/null 2>&1 || true
  elif omarchy-hyprland-toggle-enabled internal-monitor-disable; then
    omarchy-hyprland-monitor-internal on >/dev/null 2>&1 || true
  fi
}

# Hotplug settles over a few seconds, so check again after each event.
apply_with_retries() {
  local delay
  for delay in 1 2 4; do
    sleep "$delay"
    apply
  done
}

apply_with_retries

socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
while read -r event; do
  case "$event" in
    monitoradded*|monitorremoved*) apply_with_retries ;;
  esac
done < <(socat -U - "UNIX-CONNECT:$socket" 9>&-)
