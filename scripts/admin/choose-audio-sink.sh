#!/usr/bin/env bash
set -euo pipefail

DEFAULT="$(pactl get-default-sink)"
SEP=$'\t'

LIST="$(pactl --format=json list sinks | jq -r --arg s "$SEP" '.[] | "\(.name)\($s)\(.description)"')"

MENU="$(awk -F"$SEP" -v def="$DEFAULT" '{ print (($1==def)?"● ":"  ") $2 }' <<<"$LIST")"
PICK="$(printf '%s\n' "$MENU" | wofi --dmenu -p "Audio output")"
[ -z "${PICK:-}" ] && exit 0

PICK_DESC="${PICK:2}"
NEW_NAME="$(awk -F"$SEP" -v d="$PICK_DESC" '$2==d {print $1; exit}' <<<"$LIST")"
[ -z "$NEW_NAME" ] && { notify-send "Audio output" "Could not match: $PICK_DESC"; exit 1; }

pactl set-default-sink "$NEW_NAME"
notify-send -i audio-volume-high "Audio output" "$PICK_DESC"
