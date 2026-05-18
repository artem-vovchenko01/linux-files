#!/usr/bin/env bash
# Idempotent disk cleanup for Arch. Safe to run repeatedly.
#
# Usage:
#   arch-clean-disk-space.sh              # safe defaults
#   arch-clean-disk-space.sh -a           # also clear browser/npm/docker-image caches
#   arch-clean-disk-space.sh -p           # interactively pick Docker containers + images to remove
#   arch-clean-disk-space.sh --dry-run    # report sizes that would be freed
#   arch-clean-disk-space.sh --report     # just list top space hogs and exit
#
# Flags:
#   -a, --aggressive   Include rebuildable-but-painful caches: full docker image
#                      prune, docker volumes, browser HTTP caches, npm cache,
#                      Telegram media cache.
#   -p, --pick         Replace the automatic Docker prune section with an
#                      interactive picker for containers (docker ps -a) and
#                      images (docker image ls -a). Uses fzf if available,
#                      otherwise a numbered prompt.
#   -n, --dry-run      Print what each step would do/free, change nothing.
#   -r, --report       Print top space hogs across $HOME and /var, then exit.
#   -h, --help         Show this help.
set -euo pipefail
export LC_ALL=C

AGGRESSIVE=0
DRY_RUN=0
REPORT_ONLY=0
PICK=0

usage() { sed -n '2,21p' "$0" | sed 's/^# \?//'; }

while [ $# -gt 0 ]; do
    case "$1" in
        -a|--aggressive) AGGRESSIVE=1 ;;
        -p|--pick)       PICK=1 ;;
        -n|--dry-run)    DRY_RUN=1 ;;
        -r|--report)     REPORT_ONLY=1 ;;
        -h|--help)       usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
    shift
done

# ---- helpers ---------------------------------------------------------------

# avail-in-MiB on the / filesystem
avail_mib() {
    df --output=avail -BM / | tail -1 | tr -dc '0-9'
}

# du -sm but tolerant: missing dirs, permission-denied subdirs, and pipefail
# all cannot abort the script. du can exit non-zero on a partially readable
# tree (e.g. AUR pkg/ dirs owned by root); we still get a valid total on stdout.
dir_mib() {
    local p="$1" out
    [ -e "$p" ] || { echo 0; return; }
    out=$({ du -sm "$p" 2>/dev/null || true; } | awk 'END{print $1+0}')
    echo "${out:-0}"
}

fmt_mib() {
    local m="${1:-0}"
    if [ "$m" -ge 1024 ]; then
        awk -v m="$m" 'BEGIN{printf "%.2f GiB", m/1024}'
    else
        printf '%s MiB' "$m"
    fi
}

section() { printf '\n==> %s\n' "$*"; }

# Run a command, or just describe it if --dry-run.
do_run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '    [dry-run] %s\n' "$*"
    else
        eval "$@"
    fi
}

# Print: <label>: <size>   — used both standalone and pre/post deltas
report_size() {
    local label="$1" path="$2"
    local m
    m=$(dir_mib "$path")
    printf '    %-40s %s\n' "$label" "$(fmt_mib "$m")"
}

# ---- docker interactive picker --------------------------------------------
#
# Multi-select pickers for `docker ps -a` and `docker image ls -a`.
# Uses fzf with TAB-to-multi-select if available; otherwise falls back to a
# numbered list + space-separated index input (ranges like "1 3 5-8" supported).

# Read a space-separated list of indices/ranges and echo the picked lines.
# $1 = newline-separated rows, indexed from 1.
pick_by_index() {
    local rows="$1" reply
    local total
    total=$(printf '%s\n' "$rows" | wc -l)
    [ "$total" -eq 0 ] && return 0
    printf '%s\n' "$rows" | nl -ba -w3 -s'  ' >&2
    printf '    Select (e.g. "1 3 5-7", empty = none): ' >&2
    read -r reply || return 0
    [ -z "$reply" ] && return 0
    local out="" tok lo hi i
    for tok in $reply; do
        if [[ "$tok" == *-* ]]; then
            lo="${tok%-*}"; hi="${tok#*-}"
        else
            lo="$tok"; hi="$tok"
        fi
        [[ "$lo" =~ ^[0-9]+$ && "$hi" =~ ^[0-9]+$ ]] || continue
        for ((i=lo; i<=hi; i++)); do
            [ "$i" -ge 1 ] && [ "$i" -le "$total" ] || continue
            out+="$(printf '%s\n' "$rows" | sed -n "${i}p")"$'\n'
        done
    done
    printf '%s' "$out"
}

pick_lines() {
    # $1 = header text shown in fzf / printed before numbered list
    # stdin = rows
    local header="$1" rows
    rows=$(cat)
    [ -z "$rows" ] && return 0
    if command -v fzf >/dev/null; then
        printf '%s\n' "$rows" \
            | fzf -m --reverse \
                  --header="$header  (TAB: toggle, ENTER: confirm, ESC: cancel)" \
                  --prompt='> ' \
            || true
    else
        echo "    $header" >&2
        pick_by_index "$rows"
    fi
}

docker_pick_containers() {
    section "Docker: pick containers to remove"
    local rows picks ids running_picks
    # Size column requires -s; add an ID-first column for easy awk extraction.
    rows=$(docker ps -a -s --format \
        '{{.ID}}  {{.Image}}  {{.Status}}  {{.Size}}  {{.Names}}' 2>/dev/null || true)
    if [ -z "$rows" ]; then
        echo "    (no containers)"
        return
    fi
    picks=$(printf '%s\n' "$rows" | pick_lines "containers (docker ps -a)")
    if [ -z "$picks" ]; then
        echo "    (nothing selected)"
        return
    fi
    echo "    Selected:"
    printf '%s\n' "$picks" | sed 's/^/      /'
    ids=$(printf '%s\n' "$picks" | awk 'NF{print $1}')
    running_picks=$(printf '%s\n' "$picks" | awk '/  Up /{print $1}')
    if [ -n "$running_picks" ] && [ "$DRY_RUN" -eq 0 ]; then
        echo "    Some selections are running; they will be force-removed (-f)."
        printf '    Proceed? [y/N] '
        read -r yn || yn=""
        case "$yn" in y|Y|yes|YES) ;; *) echo "    (skipped)"; return ;; esac
    fi
    do_run "printf '%s\n' \"$ids\" | xargs -r docker rm -f"
}

docker_pick_images() {
    section "Docker: pick images to remove"
    local rows picks ids
    # `<none>:<none>` rows show as dangling; include digest+size for sorting by eye.
    rows=$(docker image ls -a --format \
        '{{.ID}}  {{.Repository}}:{{.Tag}}  {{.Size}}  {{.CreatedSince}}' 2>/dev/null \
        | sort -k3 -hr || true)
    if [ -z "$rows" ]; then
        echo "    (no images)"
        return
    fi
    picks=$(printf '%s\n' "$rows" | pick_lines "images (docker image ls -a, sorted by size desc)")
    if [ -z "$picks" ]; then
        echo "    (nothing selected)"
        return
    fi
    echo "    Selected:"
    printf '%s\n' "$picks" | sed 's/^/      /'
    ids=$(printf '%s\n' "$picks" | awk 'NF{print $1}')
    if [ "$DRY_RUN" -eq 0 ]; then
        printf '    Force-remove (-f) if in use by a container? [y/N] '
        read -r yn || yn=""
        case "$yn" in
            y|Y|yes|YES) do_run "printf '%s\n' \"$ids\" | xargs -r docker rmi -f" ;;
            *)           do_run "printf '%s\n' \"$ids\" | xargs -r docker rmi" ;;
        esac
    else
        do_run "printf '%s\n' \"$ids\" | xargs -r docker rmi"
    fi
}

# ---- --report mode ---------------------------------------------------------

if [ "$REPORT_ONLY" -eq 1 ]; then
    section "Filesystem usage"
    df -h / /home 2>/dev/null | awk 'NR==1 || /\// {print "    " $0}' | sort -u
    section "Top 15 in \$HOME"
    du -sh "$HOME"/* 2>/dev/null | sort -hr | head -15 | sed 's/^/    /'
    section "Top 15 in ~/.cache"
    du -sh "$HOME"/.cache/* 2>/dev/null | sort -hr | head -15 | sed 's/^/    /'
    section "Top 10 in ~/.local/share"
    du -sh "$HOME"/.local/share/* 2>/dev/null | sort -hr | head -10 | sed 's/^/    /'
    if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
        section "Docker"
        docker system df | sed 's/^/    /'
    fi
    if [ -r /var/log ]; then
        section "Journal size"
        journalctl --disk-usage 2>/dev/null | sed 's/^/    /'
    fi
    exit 0
fi

# ---- prep ------------------------------------------------------------------

if [ "$DRY_RUN" -eq 0 ]; then
    # Cache sudo creds once so prompts don't interrupt mid-run.
    sudo -v
fi

before_mib=$(avail_mib)
echo "Starting cleanup. Free space on /: $(fmt_mib "$before_mib")"
[ "$AGGRESSIVE" -eq 1 ] && echo "Aggressive mode: ON"
[ "$DRY_RUN"    -eq 1 ] && echo "Dry run: ON (no changes will be made)"

# ---- pacman ----------------------------------------------------------------

section "Pacman: keep last 1 version of installed packages"
do_run "sudo paccache -rk1"

section "Pacman: remove all cached versions of uninstalled packages"
do_run "sudo paccache -ruk0"

section "Pacman: remove orphan packages"
orphans=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$orphans" ]; then
    echo "$orphans" | sed 's/^/    - /'
    if [ "$DRY_RUN" -eq 0 ]; then
        echo "$orphans" | sudo pacman -Rns --noconfirm -
    fi
else
    echo "    (none)"
fi

# ---- AUR helper cache ------------------------------------------------------

if command -v yay >/dev/null; then
    section "yay: clean build cache (~/.cache/yay)"
    report_size "before" "$HOME/.cache/yay"
    do_run "yay -Sc --noconfirm >/dev/null 2>&1 || true"
    do_run "rm -rf \"$HOME/.cache/yay\"/*"
fi
if command -v paru >/dev/null; then
    section "paru: clean build cache"
    do_run "paru -Sc --noconfirm >/dev/null 2>&1 || true"
fi

# ---- journals & coredumps --------------------------------------------------

section "Journal: vacuum to 200M"
do_run "sudo journalctl --vacuum-size=200M"

section "Systemd coredumps: vacuum"
if [ -d /var/lib/systemd/coredump ]; then
    do_run "sudo coredumpctl --vacuum-size=0 >/dev/null 2>&1 || sudo rm -f /var/lib/systemd/coredump/*"
else
    echo "    (no coredump dir, skipping)"
fi

# ---- tmp dirs (respects systemd-tmpfiles age policy) -----------------------

section "Temp dirs: systemd-tmpfiles --clean"
do_run "sudo systemd-tmpfiles --clean 2>/dev/null || true"

# ---- user trash & thumbnails ----------------------------------------------

section "User trash: empty"
do_run "rm -rf \"$HOME/.local/share/Trash/files/\"* \"$HOME/.local/share/Trash/info/\"* 2>/dev/null || true"

section "Thumbnail cache: clear"
do_run "rm -rf \"$HOME/.cache/thumbnails/\"* 2>/dev/null || true"

# ---- language / build-tool caches -----------------------------------------

if command -v pnpm >/dev/null; then
    section "pnpm store: prune"
    do_run "pnpm store prune >/dev/null 2>&1 || true"
fi

if command -v uv >/dev/null; then
    section "uv: cache prune"
    do_run "uv cache prune >/dev/null 2>&1 || true"
fi

if command -v pip >/dev/null; then
    section "pip: cache purge"
    do_run "pip cache purge >/dev/null 2>&1 || true"
fi

if command -v cargo-cache >/dev/null; then
    section "cargo: autoclean"
    do_run "cargo-cache --autoclean >/dev/null 2>&1 || true"
elif [ -d "$HOME/.cargo/registry" ]; then
    # cargo-cache is the proper tool, but we can at least drop downloaded src tarballs.
    section "cargo: remove ~/.cargo/registry/src cache (safe; re-extracted on demand)"
    do_run "rm -rf \"$HOME/.cargo/registry/src/\"* \"$HOME/.cargo/registry/cache/\"*/*.crate.lock 2>/dev/null || true"
fi

# Trivy DB is regenerated on next scan; can be hundreds of MiB.
if [ -d "$HOME/.cache/trivy" ]; then
    section "trivy: clear DB cache (regenerated on next scan)"
    report_size "before" "$HOME/.cache/trivy"
    do_run "rm -rf \"$HOME/.cache/trivy\"/*"
fi

# ---- docker ----------------------------------------------------------------

if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
    section "Docker: pre-cleanup usage"
    docker system df | sed 's/^/    /'

    if [ "$PICK" -eq 1 ]; then
        docker_pick_containers
        docker_pick_images
        # Still safe to prune leftover dangling layers + build cache after picks.
        section "Docker: prune dangling images, unused networks, build cache"
        do_run "docker image prune -f"
        do_run "docker network prune -f"
        do_run "docker builder prune -f"
    else
        section "Docker: prune stopped containers, dangling images, unused networks, build cache"
        do_run "docker container prune -f"
        do_run "docker image prune -f"
        do_run "docker network prune -f"
        do_run "docker builder prune -f"

        if [ "$AGGRESSIVE" -eq 1 ]; then
            section "Docker (aggressive): prune ALL unused images + ALL build cache + ALL unused volumes"
            echo "    NOTE: this removes tagged-but-unused images and any volume not attached to a container."
            do_run "docker image prune -af"
            do_run "docker builder prune -af"
            do_run "docker volume prune -af"
        fi
    fi

    section "Docker: post-cleanup usage"
    docker system df | sed 's/^/    /'
else
    echo
    echo "    (docker not available, skipping)"
fi

# ---- aggressive-only: browsers, npm, Telegram ------------------------------

if [ "$AGGRESSIVE" -eq 1 ]; then
    section "npm: cache clean --force"
    if command -v npm >/dev/null; then
        report_size "before ~/.npm" "$HOME/.npm"
        do_run "npm cache clean --force >/dev/null 2>&1 || true"
    fi

    section "Browser HTTP caches (sessions/passwords untouched)"
    for d in \
        "$HOME/.cache/google-chrome" \
        "$HOME/.cache/chromium" \
        "$HOME/.cache/mozilla"; do
        if [ -d "$d" ]; then
            report_size "before" "$d"
            do_run "rm -rf \"$d\"/*"
        fi
    done

    # Telegram media cache lives under tdata/user_data/cache and tdata/media_cache.
    # Clearing it forces re-download of viewed media on next access.
    tg="$HOME/.local/share/TelegramDesktop/tdata"
    if [ -d "$tg" ]; then
        section "Telegram: clear media cache"
        for sub in "$tg"/user_data*/cache "$tg"/media_cache* "$tg"/*/cache; do
            [ -e "$sub" ] || continue
            report_size "before $(basename "$(dirname "$sub")")/cache" "$sub"
            do_run "rm -rf \"$sub\"/*"
        done
    fi
fi

# ---- summary ---------------------------------------------------------------

after_mib=$(avail_mib)
delta=$((after_mib - before_mib))
echo
echo "==> Done. Free space on /: $(fmt_mib "$before_mib") -> $(fmt_mib "$after_mib") (delta: $(fmt_mib "$delta"))"
if [ "$DRY_RUN" -eq 1 ]; then
    echo "    (dry-run: actual delta on a real run will differ)"
fi
