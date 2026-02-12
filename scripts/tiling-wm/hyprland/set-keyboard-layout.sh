#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <layout-index> <layout-code>" >&2
  exit 1
fi

layout_index="$1"
layout_code="$2"

if ! command -v jq >/dev/null 2>&1; then
  notify-send "Keyboard layout" "jq is not installed" || true
  exit 1
fi

readarray -t target_keyboards < <(
  hyprctl -j devices | jq -r '
    .keyboards
    | map(select(.main == true) | .name)
    | if length > 0 then . else
        (
          .keyboards
          | map(.name)
          | map(
              select(
                test("consumer-control|system-control|hotkeys|power-button|sleep-button|video-bus|intel-hid-events|intel-hid-5-button-array") | not
              )
            )
        )
      end
    | .[]
  '
)

if [[ "${#target_keyboards[@]}" -eq 0 ]]; then
  notify-send "Keyboard layout" "No keyboard found" || true
  exit 1
fi

for kb in "${target_keyboards[@]}"; do
  hyprctl switchxkblayout "$kb" "$layout_index" >/dev/null
done

case "$layout_code" in
  us) msg="🇺🇸 layout: us" ;;
  ua) msg="🇺🇦 layout: ua" ;;
  ru) msg="🇷🇺 layout: ru" ;;
  pl) msg="🇵🇱 layout: pl" ;;
  *)  msg="layout: $layout_code" ;;
esac

notify-send "Keyboard layout" "$msg" || true
