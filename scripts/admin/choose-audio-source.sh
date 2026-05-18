#!/usr/bin/env bash
set -euo pipefail

DEFAULT="$(pactl get-default-source)"
SEP=$'\t'

LIST="$(pactl --format=json list sources | jq -r --arg s "$SEP" '.[] | select(.name | endswith(".monitor") | not) | "\(.name)\($s)\(.description)"')"

MENU="$(awk -F"$SEP" -v def="$DEFAULT" '{ print (($1==def)?"● ":"  ") $2 }' <<<"$LIST")"
PICK="$(printf '%s\n' "$MENU" | wofi --dmenu -p "Microphone")"
[ -z "${PICK:-}" ] && exit 0

PICK_DESC="${PICK:2}"
NEW_NAME="$(awk -F"$SEP" -v d="$PICK_DESC" '$2==d {print $1; exit}' <<<"$LIST")"
[ -z "$NEW_NAME" ] && { notify-send "Microphone" "Could not match: $PICK_DESC"; exit 1; }

pactl set-default-source "$NEW_NAME"
notify-send -i audio-input-microphone "Microphone" "$PICK_DESC"
