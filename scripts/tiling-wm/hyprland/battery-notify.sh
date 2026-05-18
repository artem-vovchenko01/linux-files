#!/usr/bin/env bash
# Watches BAT0 and emits notifications on threshold crossings:
#   - >= 85% while charging  (unplug reminder)
#   - <= 20% while discharging (low)
#   - <=  5% while discharging (critical)
# Only fires once per zone change to avoid spam.

set -u

BAT=/sys/class/power_supply/BAT0
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/hypr-battery"
STATE_FILE="$STATE_DIR/zone"
INTERVAL="${BATTERY_POLL_INTERVAL:-60}"

mkdir -p "$STATE_DIR"

[[ -r "$BAT/capacity" ]] || exit 0

last_zone=""
[[ -f "$STATE_FILE" ]] && last_zone="$(cat "$STATE_FILE")"

while true; do
    capacity="$(cat "$BAT/capacity" 2>/dev/null || echo "")"
    status="$(cat "$BAT/status" 2>/dev/null || echo "Unknown")"

    if [[ "$capacity" =~ ^[0-9]+$ ]]; then
        zone="normal"
        if [[ "$status" == "Discharging" ]]; then
            if (( capacity <= 5 )); then
                zone="critical"
            elif (( capacity <= 20 )); then
                zone="low"
            fi
        elif [[ "$status" == "Charging" || "$status" == "Full" || "$status" == "Not charging" ]]; then
            if (( capacity >= 85 )); then
                zone="high"
            fi
        fi

        if [[ "$zone" != "$last_zone" ]]; then
            case "$zone" in
                critical)
                    notify-send -u critical -i battery-caution "Battery critical" "Only ${capacity}% left — plug in now."
                    ;;
                low)
                    notify-send -u normal -i battery-low "Battery low" "${capacity}% remaining."
                    ;;
                high)
                    notify-send -u normal -i battery-full-charged "Battery above 85%" "${capacity}% — consider unplugging."
                    ;;
            esac
            echo "$zone" > "$STATE_FILE"
            last_zone="$zone"
        fi
    fi

    sleep "$INTERVAL"
done
