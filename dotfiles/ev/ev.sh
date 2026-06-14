# ev — fzf TUI over a set of environment variables (sourced from .shrc.part).
#
# Run `ev`:
#   enter   re-pick the selected variable's value via its picker
#   ctrl-a  add a variable (choose one of the existing pickers)
#   ctrl-d  remove the selected variable from the vars file
#   ctrl-p  add a picker
#   ctrl-e  open the data files in $EDITOR
#
# Data files (plain text, hand-editable; '#' comments and blank lines are
# ignored, the first matching line wins):
#   vars:    <VAR> <picker-name> [on-set command]
#            The on-set command runs after the new value is exported.
#   pickers: <name> <command>
#            The command prints candidate lines; extra tab-separated columns
#            are display-only, the first column becomes the value.

EV_DIR="$HOME/linux-files/dotfiles/ev"
EV_VARS="$EV_DIR/vars"
EV_PICKERS="$EV_DIR/pickers"

_ev_lines() {
    [ -r "$1" ] || return 0
    grep -Ev '^[[:space:]]*(#|$)' "$1" | awk '!seen[$1]++'
}

_ev_rest() {
    _ev_lines "$1" | while read -r _ev_name _ev_tail; do
        if [ "$_ev_name" = "$2" ]; then
            printf '%s\n' "$_ev_tail"
            break
        fi
    done
}

_ev_has() {
    _ev_lines "$1" | awk -v n="$2" '$1 == n { found = 1 } END { exit !found }'
}

_ev_valid_var() {
    case "$1" in
        '' | [0-9]* | *[!A-Za-z0-9_]*) return 1 ;;
        *) return 0 ;;
    esac
}

_ev_valid_picker() {
    case "$1" in
        '' | *[!A-Za-z0-9_-]*) return 1 ;;
        *) return 0 ;;
    esac
}

_ev_append() {
    mkdir -p "$EV_DIR" || return 1
    if [ -s "$1" ] && [ -n "$(tail -c1 "$1")" ]; then
        printf '\n' >>"$1"
    fi
    printf '%s\n' "$2" >>"$1"
}

_ev_err() {
    printf 'ev: %s\n' "$1" >&2
    sleep 1
}

_ev_add_picker() {
    local pname pcmd
    printf 'new picker name: '
    read -r pname || return 1
    _ev_valid_picker "$pname" || { _ev_err "invalid picker name: $pname"; return 1; }
    _ev_has "$EV_PICKERS" "$pname" && { _ev_err "picker $pname exists (ctrl-e to edit)"; return 1; }
    printf 'picker command: '
    read -r pcmd || return 1
    [ -n "$pcmd" ] || { _ev_err 'empty picker command'; return 1; }
    _ev_append "$EV_PICKERS" "$pname $pcmd"
}

_ev_add_var() {
    local var pname onset
    printf 'new var name: '
    read -r var || return 1
    _ev_valid_var "$var" || { _ev_err "invalid var name: $var"; return 1; }
    _ev_has "$EV_VARS" "$var" && { _ev_err "$var exists (ctrl-e to edit)"; return 1; }
    if ! _ev_lines "$EV_PICKERS" | grep -q .; then
        _ev_err 'no pickers yet (ctrl-p to add one)'
        return 1
    fi
    pname=$(_ev_lines "$EV_PICKERS" | fzf --no-sort --prompt='picker> ') || return 1
    pname=${pname%% *}
    printf 'on-set command (optional): '
    read -r onset || return 1
    if [ -n "$onset" ]; then
        _ev_append "$EV_VARS" "$var $pname $onset"
    else
        _ev_append "$EV_VARS" "$var $pname"
    fi
}

_ev_del_var() {
    local ans tmp
    printf 'remove %s from %s? [y/N]: ' "$1" "$EV_VARS"
    read -r ans || return 1
    case "$ans" in
        y | Y | yes) ;;
        *) return 0 ;;
    esac
    tmp=$(mktemp) || return 1
    awk -v v="$1" '$1 != v' "$EV_VARS" >"$tmp" && mv "$tmp" "$EV_VARS"
}

function ev {
    command -v fzf >/dev/null 2>&1 || { echo 'ev: fzf required' >&2; return 1; }
    local out key sel var rest pname onset pcmd pick
    while :; do
        out=$(_ev_lines "$EV_VARS" | while read -r var pname onset; do
            _ev_valid_var "$var" || continue
            eval "_ev_val=\${$var-}"
            printf '%-8s %-28s [%s]\n' "$var" "$_ev_val" "$pname"
        done | fzf --no-sort \
            --header='enter repick / ^a add var / ^d del var / ^p add picker / ^e edit files' \
            --expect=ctrl-a,ctrl-d,ctrl-p,ctrl-e)
        [ -n "$out" ] || return 0
        key=$(printf '%s\n' "$out" | sed -n 1p)
        sel=$(printf '%s\n' "$out" | sed -n 2p)
        var=${sel%% *}
        case "$key" in
            ctrl-e) "${EDITOR:-vi}" "$EV_VARS" "$EV_PICKERS"; continue ;;
            ctrl-a) _ev_add_var; continue ;;
            ctrl-p) _ev_add_picker; continue ;;
            ctrl-d) [ -n "$var" ] && _ev_del_var "$var"; continue ;;
        esac
        [ -n "$var" ] || continue
        rest=$(_ev_rest "$EV_VARS" "$var")
        case "$rest" in
            *' '*) pname=${rest%% *}; onset=${rest#* } ;;
            *) pname=$rest; onset='' ;;
        esac
        pcmd=$(_ev_rest "$EV_PICKERS" "$pname")
        [ -n "$pcmd" ] || { _ev_err "$var: picker not found: $pname"; continue; }
        pick=$(eval "$pcmd" | fzf --prompt="$var> ") || continue
        pick=${pick%%$'\t'*}
        export "$var=$pick"
        if [ -n "$onset" ] && ! eval "$onset"; then
            _ev_err "on-set command failed for $var"
        fi
    done
}
