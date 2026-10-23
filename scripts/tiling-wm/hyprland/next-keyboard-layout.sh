#!/usr/bin/env bash
# menu: Hyprland: next keyboard layout, shown in the Omarchy OSD
#
# Shows all layouts, the current one in brackets (the OSD elides long text):
#   US  [UA]  RU  PL
set -euo pipefail

hyprctl switchxkblayout all next >/dev/null

# Every keyboard switched together, so any one reports the new layout.
kb=$(hyprctl -j devices | jq -c '.keyboards | (map(select(.main)) + .)[0]')
index=$(jq -r '.active_layout_index' <<<"$kb")
IFS=, read -ra layouts <<<"$(jq -r '.layout' <<<"$kb")"

list=""
for i in "${!layouts[@]}"; do
  code=${layouts[$i]^^}
  [[ $i -eq $index ]] && code="[$code]"
  list+="  $code"
done

omarchy osd -i keyboard -m "${list:2}" -d 1500
