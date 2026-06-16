#!/bin/bash

# claude-billing  --  switch Claude Code between a third-party provider
# (Vertex / Bedrock / proxy) and the Anthropic subscription login.
#
# The provider config lives in ~/.claude/settings.json under .env. When
# CLAUDE_CODE_USE_VERTEX/BEDROCK is set there, every session bills the cloud
# account no matter which account you logged in with. This toggles that env
# block: switching to "sub" snapshots the current provider env to a profile and
# strips it; switching to "provider" restores the snapshot.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
PROFILE_DIR="$HOME/.claude/billing-profiles"
PROFILE="$PROFILE_DIR/provider.json"

# Provider-neutral model aliases kept while on subscription (resolve on either
# backend). Vertex-form ids like claude-haiku-4-5@date do NOT work here.
SUB_ENV='{"ANTHROPIC_DEFAULT_SONNET_MODEL":"claude-sonnet-4-6","ANTHROPIC_DEFAULT_OPUS_MODEL":"claude-opus-4-8"}'

# Fallback provider env if no snapshot exists yet (Artem's Vertex setup).
DEFAULT_PROVIDER_ENV='{"CLAUDE_CODE_USE_VERTEX":"1","ANTHROPIC_VERTEX_PROJECT_ID":"hl2-epmp-mvis-t1iylu","CLOUD_ML_REGION":"global","ANTHROPIC_DEFAULT_SONNET_MODEL":"claude-sonnet-4-6","ANTHROPIC_DEFAULT_OPUS_MODEL":"claude-opus-4-8","ANTHROPIC_DEFAULT_HAIKU_MODEL":"claude-haiku-4-5@20251001"}'

command -v jq >/dev/null || { echo "anomaly: jq not found" >&2; exit 1; }
[ -f "$SETTINGS" ] || { echo "anomaly: $SETTINGS missing" >&2; exit 1; }

current_mode() {
  local v
  v=$(jq -r '.env.CLAUDE_CODE_USE_VERTEX // .env.CLAUDE_CODE_USE_BEDROCK // empty' "$SETTINGS")
  [ "$v" = "1" ] && echo provider || echo subscription
}

# jq cannot edit in place; write to a temp file and move it over atomically.
apply_env() {
  local newenv="$1" tmp
  cp "$SETTINGS" "$SETTINGS.bak"
  tmp=$(mktemp)
  jq --argjson e "$newenv" '.env = $e' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
}

to_subscription() {
  mkdir -p "$PROFILE_DIR"
  jq '.env' "$SETTINGS" > "$PROFILE"
  apply_env "$SUB_ENV"
  echo "Claude Code -> Anthropic subscription billing."
  echo "Provider env snapshot saved to $PROFILE"
}

to_provider() {
  local penv
  if [ -f "$PROFILE" ]; then
    penv=$(cat "$PROFILE")
  else
    penv="$DEFAULT_PROVIDER_ENV"
    echo "No snapshot found; using built-in default provider env."
  fi
  apply_env "$penv"
  echo "Claude Code -> third-party provider billing (Vertex/Bedrock)."
}

status() {
  echo "mode: $(current_mode)"
  echo "settings env:"
  jq '.env' "$SETTINGS"
}

case "${1:-toggle}" in
  sub|subscription|anthropic|off) to_subscription ;;
  provider|vertex|bedrock|on)     to_provider ;;
  status)                         status; exit 0 ;;
  toggle)
    [ "$(current_mode)" = provider ] && to_subscription || to_provider ;;
  -h|--help|help)
    echo "usage: claude-billing [sub|provider|toggle|status]"; exit 0 ;;
  *) echo "anomaly: unknown arg '$1'" >&2; exit 1 ;;
esac

echo "Restart Claude Code for the change to take effect (env is read at startup)."
