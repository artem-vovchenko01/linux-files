#!/bin/bash

# share-sessions.sh  --  let an alt-account home reuse the primary account's
# machine-local session state.
#
# Every one of these CLIs has a single "home" env var (CODEX_HOME, GROK_HOME,
# CLAUDE_CONFIG_DIR) that roots both the login and the recorded state.
# The *-alt wrappers point it at a second directory to keep the logins apart.
# The transcripts themselves are symlinks into ~/DATA/agentic-context in both
# homes (its link-contexts.sh makes them). What this links is the rest: prompt
# history, shell snapshots, and indexes that belong to this machine.
#
# Pointing those alt-home entries at the primary home's keeps one pool while
# each home keeps its own credential file.
#
# Usage: source this file, then
#   share_sessions <primary_home> <alt_home> dir:<name> file:<name> ...
# Names are relative to the home directory. Run it on every launch; it is a
# few stat calls once the links are in place.
#
# The first run also carries over what the alt home already recorded:
# directory contents are merged into the primary (a name already there wins),
# and a plain file is set aside as <name>.local-<timestamp>.

share_sessions() {
  local primary=$1 alt=$2
  shift 2
  [ -d "$primary" ] || return 0
  mkdir -p "$alt"

  local entry kind name tgt lnk
  for entry in "$@"; do
    kind=${entry%%:*}
    name=${entry#*:}
    tgt=$primary/$name
    lnk=$alt/$name

    [ -L "$lnk" ] && [ "$(readlink "$lnk")" = "$tgt" ] && continue

    if [ "$kind" = dir ]; then
      mkdir -p "$tgt"
    else
      [ -e "$tgt" ] || : > "$tgt"
    fi

    if [ -e "$lnk" ] && [ ! -L "$lnk" ]; then
      if [ "$kind" = dir ]; then
        cp -a -n "$lnk/." "$tgt/" 2>/dev/null
        rm -rf "$lnk"
      else
        mv "$lnk" "$lnk.local-$(date +%Y%m%d-%H%M%S)"
      fi
    fi

    rm -f "$lnk"
    ln -sfn "$tgt" "$lnk"
  done
}
