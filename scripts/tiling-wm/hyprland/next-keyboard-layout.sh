#!/usr/bin/env bash
# menu: Hyprland: next keyboard layout, shown in a large popup at the top
#
# The popup is the artem.layout-osd shell plugin
# (~/linux-files/dotfiles/omarchy/plugins/). It lists all layouts and
# highlights the active one.
set -euo pipefail

hyprctl switchxkblayout all next >/dev/null

# Every keyboard switched together, so any one reports the new layout.
kb=$(hyprctl -j devices | jq -c '.keyboards | (map(select(.main)) + .)[0]')

payload=$(jq -c '{
  layouts: (.layout | ascii_upcase | split(",")),
  index: .active_layout_index,
  duration: 1200
}' <<<"$kb")

omarchy-shell -q shell summon artem.layout-osd "$payload" >/dev/null
