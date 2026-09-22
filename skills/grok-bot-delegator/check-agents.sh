#!/usr/bin/env bash
# check-agents.sh -- what can this machine delegate to right now?
#
# Prints one line per CLI agent account: logged in or not, which account, and
# how much subscription usage is left. It reads local credential files and the
# providers' own status endpoints, so it costs no model usage.
#
# Usage:
#   ./check-agents.sh            every agent, primary and second account
#   ./check-agents.sh claude     one agent only (claude | codex | grok | opencode)

set -uo pipefail
want="${1:-all}"

row() { printf '%-12s %s\n' "$1" "$2"; }

# Anthropic reports subscription usage over OAuth. The token in the config dir
# is also the account that gets billed, so ask the API who it belongs to rather
# than the CLI: `claude auth status` can answer for a different login.
# Usage: claude_api ~/.claude profile  ->  raw JSON on stdout, empty on failure
claude_api() {
  local tok api=https://api.anthropic.com/api/oauth
  tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$1/.credentials.json" 2>/dev/null)
  [ -n "$tok" ] || return 1
  curl -sf "$api/$2" -H "Authorization: Bearer $tok" \
       -H "anthropic-beta: oauth-2025-04-20"
}

check_claude() {
  local dir="$1" label="$2" prof usage
  command -v claude >/dev/null || { row "$label" "not installed"; return; }
  [ -r "$dir/.credentials.json" ] || { row "$label" "LOGGED OUT ($dir)"; return; }
  prof=$(claude_api "$dir" profile) || {
    row "$label" "NOT USABLE — logged out or token expired; confirm with: CLAUDE_CONFIG_DIR=$dir claude auth status"
    return
  }
  usage=$(claude_api "$dir" usage | jq -r '
    [.limits[] | select(.kind=="session" or .kind=="weekly_all")
     | "\(.kind) \(.percent|round)%"] | join(", ")')
  row "$label" "$(jq -r '"\(.account.email) (\(.organization.organization_type))"' \
    <<<"$prof") — ${usage:-usage unknown}"
}

# Codex has no usage command. Every session writes a rate-limit snapshot into
# its rollout transcript, so the newest one carries the last known numbers:
# primary = the 5h window, secondary = the weekly window. The numbers are as
# old as the last codex run, and the two accounts share one session store, so
# a snapshot does not say which account it came from.
codex_usage() {
  local home="$1" f
  f=$(find -L "$home/sessions" -name 'rollout-*.jsonl' -printf '%T@ %p\n' \
        2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
  [ -n "${f:-}" ] || { echo "usage unknown (no sessions yet)"; return; }
  grep -h '"rate_limits"' "$f" 2>/dev/null | tail -1 | jq -r '
    .payload.rate_limits as $r
    | "5h \($r.primary.used_percent|round)%, week \($r.secondary.used_percent|round)%"
      + " (plan \($r.plan_type), snapshot \(.timestamp[0:16]), either account)"' 2>/dev/null \
    || echo "usage unknown"
}

check_codex() {
  local home="$1" label="$2"
  command -v codex >/dev/null || { row "$label" "not installed"; return; }
  if ! CODEX_HOME="$home" codex login status >/dev/null 2>&1; then
    row "$label" "LOGGED OUT ($home)"
    return
  fi
  row "$label" "$(CODEX_HOME="$home" codex login status 2>&1 | head -1) — $(codex_usage "$home")"
}

# Grok CLI reports no quota at all: its own docs say a rate-limit summary is
# "a number it cannot source honestly" (~/.grok/docs/user-guide/25-status-line.md).
# Treat grok as the fallback whose remaining usage you learn only by using it.
check_grok() {
  local home="$1" label="$2" out
  command -v grok >/dev/null || { row "$label" "not installed"; return; }
  out=$(GROK_HOME="$home" grok models 2>&1)
  case "$out" in
    *"logged in"*) row "$label" "$(head -1 <<<"$out") default $(sed -n 's/^Default model: //p' <<<"$out") — usage not reported by the CLI" ;;
    *) row "$label" "LOGGED OUT ($home)" ;;
  esac
}

# opencode keeps all provider logins in one file; the OpenCode Go entry is what
# the light ladder bills. Like Grok, it reports no quota.
check_opencode() {
  local auth="$HOME/.local/share/opencode/auth.json"
  command -v opencode >/dev/null || { row opencode "not installed"; return; }
  if jq -e '.["opencode-go"]' "$auth" >/dev/null 2>&1; then
    row opencode "OpenCode Go — usage not reported by the CLI"
  else
    row opencode "LOGGED OUT ($auth)"
  fi
}

case "$want" in
  all|claude) check_claude "$HOME/.claude" claude
              check_claude "$HOME/.claude-alt" claude-alt ;;&
  all|codex)  check_codex "$HOME/.codex" codex
              check_codex "$HOME/.codex-alt" codex-alt ;;&
  all|grok)   check_grok "$HOME/.grok" grok
              check_grok "$HOME/.grok-alt" grok-alt ;;&
  all|opencode) check_opencode ;;&
  all|claude|codex|grok|opencode) ;;
  *) echo "usage: $0 [claude|codex|grok|opencode]" >&2; exit 64 ;;
esac
