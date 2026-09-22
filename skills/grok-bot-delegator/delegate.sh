#!/usr/bin/env bash
# delegate.sh -- hand one task to a CLI coding agent and print what it returns.
#
# It walks a preference ladder, skips an agent that is not installed or not
# logged in, runs the first one that is usable, and falls through to the next
# if that run fails. Two ladders:
#   demanding work (default)  claude -> codex -> grok
#   light work (-l)           opencode -> grok -> codex -> claude
# The last line of output always names the agent, model, account and session id
# behind the answer.
#
# Usage:
#   ./delegate.sh "summarise the git log of the last week"
#   ./delegate.sh -f brief.md -d ~/EPAM/migvisor_explainer
#   ./delegate.sh -a codex -m gpt-6-astra -e high "refactor the loader"
#   ./delegate.sh -l "what is the status of EPMPMVISEX-1201"
#
# Options:
#   -a AGENT    claude | codex | grok | opencode   (default: whole ladder)
#   -l          light task: use the opencode -> grok -> codex -> claude ladder
#   -m MODEL    model id                   (default per agent, see MODEL_*)
#   -e EFFORT   reasoning effort           (default medium)
#   -d DIR      working directory for the run   (default: $PWD)
#   -t SECONDS  hard timeout per attempt        (default 1800)
#   -f FILE     read the task from FILE instead of the argument
#   -A          use the second account of that agent (claude-alt, codex-alt...)
#   -R          send the task text raw, without the unattended-run preamble
#   -n          dry run: print the command that would run, run nothing

set -uo pipefail

MODEL_claude=claude-opus-5
MODEL_codex=gpt-6-astra
MODEL_grok=grok-4.6
MODEL_opencode=opencode-go/deepseek-flash

agent="" model="" effort=medium dir="$PWD" tmo=1800 file="" alt=0 raw=0 dry=0
light=0
while getopts "a:m:e:d:t:f:lARnh" o; do
  case "$o" in
    a) agent=$OPTARG ;; m) model=$OPTARG ;; e) effort=$OPTARG ;;
    d) dir=$OPTARG ;;   t) tmo=$OPTARG ;;  f) file=$OPTARG ;;
    l) light=1 ;;       A) alt=1 ;;        R) raw=1 ;;
    n) dry=1 ;;
    h|*) awk 'NR>1 && /^#/ {print; next} NR>1 {exit}' "$0"; exit 64 ;;
  esac
done
shift $((OPTIND - 1))

if [ -n "$file" ]; then task=$(cat "$file"); else task="${*:-}"; fi
[ -n "$task" ] || { echo "delegate.sh: no task given" >&2; exit 64; }
[ -d "$dir" ] || { echo "delegate.sh: no such directory: $dir" >&2; exit 64; }

# The delegate starts cold and nobody is watching it. Say so up front, or it
# stops halfway to ask a question that no one will answer.
if [ "$raw" -eq 0 ]; then
  task="You are running unattended from a script. Nobody can answer questions
mid-run: decide the reasonable thing and say what you assumed. Work in $dir.
Finish with a short report of what you did, what you changed, and anything you
could not do.

TASK:
$task"
fi

# Both accounts of an agent stay logged in side by side, each in its own home
# directory. The wrapper scripts set that up and scrub env vars that would
# otherwise redirect billing; use them when they are on PATH.
# Usage: runner claude  ->  prints "claude" or "claude-alt", and exports homes
runner() {
  local a="$1"
  [ "$alt" -eq 0 ] && { echo "$a"; return; }
  case "$a" in
    claude) export CLAUDE_CONFIG_DIR="$HOME/.claude-alt" ;;
    codex)  export CODEX_HOME="$HOME/.codex-alt" ;;
    grok)   export GROK_HOME="$HOME/.grok-alt" ;;
  esac
  if command -v "$a-alt" >/dev/null; then echo "$a-alt"; else echo "$a"; fi
}

# Usage: usable claude  ->  exit 0 when that CLI is installed and logged in
usable() {
  local out
  command -v "$1" >/dev/null || return 1
  case "$1" in
    claude) [ -r "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json" ] ;;
    codex)  codex login status >/dev/null 2>&1 ;;
    # Piping grok into grep kills it with SIGPIPE, so read the output first.
    grok)   out=$(grok models 2>&1); case "$out" in *"logged in"*) ;; *) return 1 ;; esac ;;
    opencode) jq -e '.["opencode-go"]' "$HOME/.local/share/opencode/auth.json" >/dev/null 2>&1 ;;
  esac
}

# The generic ladder effort does not always exist on an agent's model. Map it
# to the closest real setting. opencode's DeepSeek V4.1 Flash offers only low,
# high and max, so medium lands on high.
# Usage: effort_for opencode  ->  high
effort_for() {
  case "$1" in
    opencode) case "$effort" in
                low) echo low ;;
                xhigh|max) echo max ;;
                *) echo high ;;
              esac ;;
    *) echo "$effort" ;;
  esac
}

# Which account slot paid for the run. The home directory is the identity: the
# two accounts of an agent differ only by the directory their login sits in.
# Usage: account_of claude  ->  ".claude (pro)"
account_of() {
  case "$1" in
    claude) echo "$(basename "${CLAUDE_CONFIG_DIR:-$HOME/.claude}") ($(jq -r \
              '.claudeAiOauth.subscriptionType // "?"' \
              "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json" 2>/dev/null))" ;;
    codex)  echo "$(basename "${CODEX_HOME:-$HOME/.codex}") (ChatGPT)" ;;
    grok)   echo "$(basename "${GROK_HOME:-$HOME/.grok}") (grok.com)" ;;
    opencode) echo "opencode (OpenCode Go)" ;;
  esac
}

run_claude() {
  local out
  out=$(cd "$dir" && timeout "$tmo" "$bin" -p "$task" --model "$m" \
        --effort "$effort" --output-format json --dangerously-skip-permissions 2>&1)
  rc=$?
  text=$(jq -r '.result // empty' <<<"$out" 2>/dev/null)
  sid=$(jq -r '.session_id // empty' <<<"$out" 2>/dev/null)
  [ -n "$text" ] || { text="$out"; [ "$rc" -eq 0 ] && rc=1; }
}

run_codex() {
  local last log
  last=$(mktemp) log=$(mktemp)
  (cd "$dir" && timeout "$tmo" "$bin" exec -m "$m" \
     -c model_reasoning_effort="$effort" --skip-git-repo-check \
     --dangerously-bypass-approvals-and-sandbox -o "$last" "$task") \
     >"$log" 2>&1 </dev/null
  rc=$?
  text=$(cat "$last"); sid=$(sed -n 's/^session id: //p' "$log" | head -1)
  [ -n "$text" ] || { text=$(tail -30 "$log"); [ "$rc" -eq 0 ] && rc=1; }
  rm -f "$last" "$log"
}

run_grok() {
  local out
  out=$(timeout "$tmo" "$bin" -p "$task" --model "$m" \
        --reasoning-effort "$effort" --cwd "$dir" \
        --permission-mode bypassPermissions --output-format json 2>&1)
  rc=$?
  text=$(jq -r '.text // empty' <<<"$out" 2>/dev/null)
  sid=$(jq -r '.sessionId // empty' <<<"$out" 2>/dev/null)
  [ -n "$text" ] || { text="$out"; [ "$rc" -eq 0 ] && rc=1; }
}

# opencode's --format json prints one event per line: the answer is split across
# the "text" events, and every event carries the session id.
run_opencode() {
  local out log
  log=$(mktemp)
  out=$(cd "$dir" && timeout "$tmo" "$bin" run -m "$m" --variant "$ae" \
        --auto --format json "$task" 2>"$log")
  rc=$?
  text=$(printf '%s\n' "$out" | jq -rs \
    '[.[]? | select(.type=="text") | .part.text] | join("\n")' 2>/dev/null)
  sid=$(printf '%s\n' "$out" | jq -r 'select(.sessionID!=null) | .sessionID' 2>/dev/null | head -1)
  if [ -z "$text" ]; then
    text=$(tail -30 "$log"); [ -n "$text" ] || text="$out"
    [ "$rc" -eq 0 ] && rc=1
  fi
  rm -f "$log"
}

if [ "$light" -eq 1 ]; then default_ladder="opencode grok codex claude"
else default_ladder="claude codex grok"; fi
ladder=${agent:-$default_ladder}
for a in $ladder; do
  bin=$(runner "$a")
  d=MODEL_$a; m=${model:-${!d}}
  ae=$(effort_for "$a")
  if ! usable "$a"; then
    echo "delegate.sh: $bin is not installed or not logged in — next" >&2
    continue
  fi
  if [ "$dry" -eq 1 ]; then
    echo "would run: $bin ($m, effort $ae) in $dir, timeout ${tmo}s"
    exit 0
  fi
  start=$SECONDS text="" sid="" rc=0
  "run_$a"
  printf '%s\n' "$text"
  printf -- '--- delegated: %s / %s / effort %s / account %s / session %s / exit %s / %ss\n' \
    "$bin" "$m" "$ae" "$(account_of "$a")" "${sid:-unknown}" "$rc" "$((SECONDS - start))"
  [ "$rc" -eq 0 ] && exit 0
  echo "delegate.sh: $bin failed (exit $rc) — trying the next agent" >&2
done

echo "delegate.sh: no agent could run this task" >&2
exit 1
