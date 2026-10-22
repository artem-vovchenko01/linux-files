#!/usr/bin/env bash
# menu: Find and run my scripts (this menu). Type to search, Enter to run.
#
# cmds [QUERY]   fuzzy list of every script in the sources, with a one-line
#                description and the script's header in a preview pane.
#
# Keys: Enter run (asks for arguments), Ctrl-E edit, Ctrl-Y copy path,
#       Ctrl-/ toggle preview, Esc quit.
#
# Sources: scripts/cmds.sources lists "LABEL DIR" lines and may
# "include FILE" another sources file (the work hub adds its own that way).
# Description: a "# menu: ..." line if the script has one, else its first
# comment line. Each dir's .menu_config IGNORE= names are left out, the same
# as menu.sh (the wofi menu).
set -uo pipefail

SELF=$(readlink -f "$0")
LF_SCRIPTS=$(dirname "$SELF")
SOURCES=$LF_SCRIPTS/cmds.sources

# describe FILE: the "# menu:" line, or the first plain comment after the
# shebang that is not a "set -x" style line.
describe() {
	local d
	d=$(grep -m1 '^# menu:' "$1" 2>/dev/null | sed 's/^# menu: *//')
	[ -z "$d" ] && d=$(sed -n '2,15{/^#!/d;/^# *$/d;/^# *-\*-/d;/^#/{s/^# *//;p;q}}' "$1" 2>/dev/null)
	[ -z "$d" ] && [[ "$1" == *.py ]] && d=$(sed -n '2,15{s/^"""//;/^#/d;/^ *$/d;p;q}' "$1" 2>/dev/null)
	echo "${d:0:70}"
}

# read_sources FILE: print "LABEL<TAB>DIR", following includes once.
read_sources() {
	local file=$1 label dir
	[ -f "$file" ] || return 0
	while read -r label dir; do
		[[ -z "$label" || "$label" == \#* ]] && continue
		dir=${dir/#\~/$HOME}
		if [ "$label" = include ]; then
			read_sources "$dir"
		elif [ -d "$dir" ]; then
			printf '%s\t%s\n' "$label" "$dir"
		fi
	done < "$file"
}

# ignored DIR NAME: listed in that dir's .menu_config IGNORE= line.
ignored() {
	local cfg=$1/.menu_config
	[ -f "$cfg" ] && grep -m1 '^IGNORE=' "$cfg" | cut -d= -f2 | tr ' ' '\n' | grep -qx "$2"
}

list() {
	local label dir f rel skip part sub
	while IFS=$'\t' read -r label dir; do
		while IFS= read -r f; do
			rel=${f#"$dir"/}
			[[ "/$rel" == */.* ]] && continue
			# Walk the path so an ignored folder hides everything under it.
			skip=0 sub=$dir
			IFS=/ read -ra parts <<<"$rel"
			for part in "${parts[@]}"; do
				ignored "$sub" "$part" && { skip=1; break; }
				sub=$sub/$part
			done
			(( skip )) && continue
			printf '%s\t%-12s %-44s %s\n' "$f" "$label" "${rel%.*}" "$(describe "$f")"
		done < <(find -L "$dir" -type f \( -name '*.sh' -o -name '*.py' \) \
			-not -path '*/node_modules/*' -not -path '*/systemd/*' \
			-not -name 'cmds.sh' 2>/dev/null | sort)
	done < <(read_sources "$SOURCES")
}

run() {
	local f=$1 args
	echo "$f"
	read -r -e -p "args: " args || return
	cd "$(dirname "$f")" || return
	case "$f" in
		*.py) eval "python3 \"\$f\" $args" ;;
		*) if [ -x "$f" ]; then eval "\"\$f\" $args"; else eval "bash \"\$f\" $args"; fi ;;
	esac
}

if ! command -v fzf &>/dev/null; then
	echo "cmds needs fzf." >&2
	exit 1
fi

PREVIEW='sed -n "1,40p" {1} | grep -E "^#|^\s*$|usage|Usage" | head -30'
command -v bat &>/dev/null && PREVIEW='bat --style=plain --color=always --line-range=:40 {1}'

choice=$(list | fzf --delimiter=$'\t' --with-nth=2 --query="${1:-}" \
	--prompt='cmds> ' --header='Enter run · Ctrl-E edit · Ctrl-Y copy path · Ctrl-/ preview' \
	--preview="$PREVIEW" --preview-window='right,50%,wrap' \
	--bind='ctrl-/:toggle-preview' \
	--bind="ctrl-y:execute-silent(printf %s {1} | wl-copy)+abort" \
	--expect=ctrl-e) || exit 0

key=$(sed -n 1p <<<"$choice")
file=$(sed -n 2p <<<"$choice" | cut -f1)
[ -n "$file" ] || exit 0
if [ "$key" = ctrl-e ]; then
	exec "${EDITOR:-nvim}" "$file"
fi
run "$file"
