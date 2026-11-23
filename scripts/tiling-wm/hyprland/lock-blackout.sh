#!/usr/bin/env bash
# Black out active external monitor(s) while locked without cutting DPMS signal,
# so a monitor's built-in USB hub and wired Ethernet stay online. On the laptop
# panel alone (no active external monitor), fall through to real DPMS sleep.
set -u

SELF=$(readlink -f "$0")
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/lock-blackout"
LOCK="$STATE/lock"
mkdir -p "$STATE"

locked() {
	[[ $(omarchy-shell lock isLocked 2>/dev/null) == true ]]
}

ensure_hyprsunset() {
	hyprctl hyprsunset gamma >/dev/null 2>&1 && return 0
	if ! pgrep -x hyprsunset >/dev/null 2>&1; then
		setsid hyprsunset --identity >/dev/null 2>&1 </dev/null 9>&- &
	fi
	local i
	for i in {1..20}; do
		hyprctl hyprsunset gamma >/dev/null 2>&1 && return 0
		sleep 0.1
	done
	return 1
}

read_gamma() {
	local g
	g=$(hyprctl hyprsunset gamma 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?' | head -n1)
	if [[ -z $g ]] || awk "BEGIN{exit !($g <= 0)}"; then
		echo 100
	else
		echo "$g"
	fi
}

bus_for_monitor() {
	local mon="$1"
	local cache="${XDG_RUNTIME_DIR:-/tmp}/omarchy-brightness-display-ddc/${mon//[^[:alnum:]_.-]/_}.bus"
	local bus=""
	if [[ -r $cache ]]; then
		read -r bus _ <"$cache" || true
		[[ $bus =~ ^[0-9]+$ ]] && { echo "$bus"; return 0; }
	fi
	bus=$(ddcutil --skip-ddc-checks detect --brief 2>/dev/null | awk -v m="$mon" '
		/I2C bus:/ { sub(/^.*\/i2c-/, "", $NF); b = $NF }
		/DRM connector:/ {
			c = $NF; sub(/^card[0-9]+-/, "", c)
			if (c == m && b ~ /^[0-9]+$/) { print b; exit }
			b = ""
		}
	')
	[[ $bus =~ ^[0-9]+$ ]] && echo "$bus"
}

dim_ddc_bg() {
	command -v ddcutil >/dev/null 2>&1 || return 0
	local mons mon bus raw
	mons=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.disabled == false and (.name | test("^(eDP|LVDS|DSI|FALLBACK|HEADLESS)") | not)) | .name')
	[[ -n $mons ]] || return 0
	: >"$STATE/ddc.tmp"
	for mon in $mons; do
		[[ -f $STATE/active ]] || { rm -f "$STATE/ddc.tmp"; return 0; }
		bus=$(bus_for_monitor "$mon") || continue
		[[ -n $bus ]] || continue
		raw=$(ddcutil --bus "$bus" --skip-ddc-checks getvcp 10 --brief 2>/dev/null | awk '$1=="VCP" && toupper($2)=="10" && $4 ~ /^[0-9]+$/ { print $4; exit }')
		[[ $raw =~ ^[0-9]+$ ]] || continue
		if (( raw > 0 )); then
			printf '%s %s\n' "$bus" "$raw" >>"$STATE/ddc.tmp"
		fi
		if [[ -f $STATE/active ]]; then
			ddcutil --bus "$bus" --skip-ddc-checks --noverify setvcp 10 0 >/dev/null 2>&1 || true
			# If wake happened mid-I2C call, immediately put brightness back.
			if [[ ! -f $STATE/active && $raw -gt 0 ]]; then
				ddcutil --bus "$bus" --skip-ddc-checks --noverify setvcp 10 "$raw" >/dev/null 2>&1 || true
			fi
		fi
	done
	if [[ -f $STATE/active && -s $STATE/ddc.tmp ]]; then
		mv -f "$STATE/ddc.tmp" "$STATE/ddc"
	else
		rm -f "$STATE/ddc.tmp"
	fi
}

restore_ddc_bg() {
	local file="$1"
	command -v ddcutil >/dev/null 2>&1 || { rm -f "$file"; return 0; }
	local bus raw
	while read -r bus raw; do
		[[ $bus =~ ^[0-9]+$ && $raw =~ ^[0-9]+$ ]] || continue
		ddcutil --bus "$bus" --skip-ddc-checks --noverify setvcp 10 "$raw" >/dev/null 2>&1 || true
	done <"$file"
	rm -f "$file"
}

stop_watcher() {
	if [[ -f $STATE/watch.pid ]]; then
		local pid
		pid=$(cat "$STATE/watch.pid" 2>/dev/null || true)
		rm -f "$STATE/watch.pid"
		if [[ $pid =~ ^[0-9]+$ ]] && [[ $pid != "$$" ]]; then
			pkill -TERM -P "$pid" 2>/dev/null || true
			kill -TERM "$pid" 2>/dev/null || true
		fi
	fi
}

do_wake() {
	exec 9>"$LOCK"
	flock 9
	local was_active=0
	[[ -f $STATE/active ]] && was_active=1
	rm -f "$STATE/active"
	local gamma=100
	if [[ -f $STATE/gamma ]]; then
		gamma=$(cat "$STATE/gamma" 2>/dev/null || echo 100)
		rm -f "$STATE/gamma"
	fi
	if [[ ! $gamma =~ ^[0-9]+(\.[0-9]+)?$ ]] || awk "BEGIN{exit !($gamma <= 0)}"; then
		gamma=100
	fi
	if (( was_active )) || pgrep -x hyprsunset >/dev/null 2>&1; then
		local cur
		cur=$(hyprctl hyprsunset gamma 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?' | head -n1 || true)
		if (( was_active )) || [[ -n $cur && $(awk "BEGIN{print ($cur < 1)}") == 1 ]]; then
			hyprctl hyprsunset gamma "$gamma" >/dev/null 2>&1 || true
		fi
	fi
	if [[ -f $STATE/ddc ]]; then
		local snap="$STATE/ddc.restore.$$"
		mv -f "$STATE/ddc" "$snap"
		setsid bash -c 'exec "$1" restore-ddc "$2"' _ "$SELF" "$snap" >/dev/null 2>&1 </dev/null 9>&- &
	fi
	if [[ -f $STATE/ddc.tmp ]]; then
		local snap2="$STATE/ddc.restore2.$$"
		mv -f "$STATE/ddc.tmp" "$snap2"
		setsid bash -c 'exec "$1" restore-ddc "$2"' _ "$SELF" "$snap2" >/dev/null 2>&1 </dev/null 9>&- &
	fi
	stop_watcher
}

do_watch() {
	local sway_pid="" cursor now_cursor elapsed=0
	cleanup() {
		[[ -n $sway_pid ]] && kill -TERM "$sway_pid" 2>/dev/null || true
	}
	trap cleanup EXIT INT TERM
	cursor=$(hyprctl cursorpos 2>/dev/null || true)
	if command -v swayidle >/dev/null 2>&1; then
		swayidle -w timeout 1 'true' resume "$SELF wake" >/dev/null 2>&1 </dev/null &
		sway_pid=$!
	fi
	while [[ -f $STATE/active ]]; do
		if ! locked; then
			"$SELF" wake
			break
		fi
		if ! omarchy-hyprland-monitor-external-active; then
			"$SELF" wake
			break
		fi
		if (( elapsed < 10 )); then
			now_cursor=$(hyprctl cursorpos 2>/dev/null || true)
			if [[ -n $cursor && -n $now_cursor && $now_cursor != "$cursor" ]]; then
				"$SELF" wake
				break
			fi
		fi
		if [[ -n $sway_pid ]] && ! kill -0 "$sway_pid" 2>/dev/null; then
			swayidle -w timeout 1 'true' resume "$SELF wake" >/dev/null 2>&1 </dev/null &
			sway_pid=$!
		fi
		sleep 0.3
		(( elapsed += 1 ))
	done
}

do_blank() {
	local force="${1:-}"
	if ! omarchy-hyprland-monitor-external-active; then
		[[ -f $STATE/active ]] && do_wake
		hyprctl dispatch 'hl.dsp.dpms({ action = "disable", _real = true })' >/dev/null 2>&1 || true
		return 0
	fi
	if [[ $force != "--force" ]] && ! locked; then
		return 0
	fi
	exec 9>"$LOCK"
	flock 9
	if ! ensure_hyprsunset; then
		return 0
	fi
	if [[ ! -f $STATE/active ]]; then
		read_gamma >"$STATE/gamma"
		date +%s >"$STATE/active"
		setsid bash -c 'exec "$1" dim-ddc' _ "$SELF" >/dev/null 2>&1 </dev/null 9>&- &
	fi
	hyprctl hyprsunset gamma 0 >/dev/null 2>&1 || true
	stop_watcher
	if [[ $force != "--force" ]]; then
		setsid "$SELF" watch >/dev/null 2>&1 </dev/null 9>&- &
		echo $! >"$STATE/watch.pid"
	fi
}

case "${1:-}" in
blank) do_blank "${2:-}" ;;
wake) do_wake ;;
watch) do_watch ;;
dim-ddc) dim_ddc_bg ;;
restore-ddc) restore_ddc_bg "${2:-}" ;;
status)
	[[ -f $STATE/active ]] && echo "blacked-out" || echo "normal"
	;;
*)
	echo "usage: $0 blank|wake|status" >&2
	exit 2
	;;
esac
