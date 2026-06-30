#!/bin/bash

# claude-configure — switch Claude Code between billing/routing backends.
# Providers: sub (Anthropic subscription), vertex (Google Vertex AI),
#            openrouter (OpenRouter proxy).
#
# Provider env lives in ~/.claude/settings.json under .env.  This script
# rewrites that block atomically; each non-sub provider's env is snapshotted
# to ~/.claude/billing-profiles/<provider>.json for safe round-tripping.
#
# OpenRouter key is read from ~/.local/share/opencode/auth.json (.openrouter.key).

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
PROFILE_DIR="$HOME/.claude/billing-profiles"
OPENCODE_AUTH="$HOME/.local/share/opencode/auth.json"

# Model aliases valid on the direct Anthropic API (not Vertex-form IDs with @date).
SUB_ENV='{"ANTHROPIC_DEFAULT_SONNET_MODEL":"claude-sonnet-4-6","ANTHROPIC_DEFAULT_OPUS_MODEL":"claude-opus-4-8"}'

# Built-in fallback used when no saved vertex snapshot exists.
DEFAULT_VERTEX_ENV='{"CLAUDE_CODE_USE_VERTEX":"1","ANTHROPIC_VERTEX_PROJECT_ID":"hl2-epmp-mvis-t1iylu","CLOUD_ML_REGION":"global","ANTHROPIC_DEFAULT_SONNET_MODEL":"claude-sonnet-4-6","ANTHROPIC_DEFAULT_OPUS_MODEL":"claude-opus-4-8","ANTHROPIC_DEFAULT_HAIKU_MODEL":"claude-haiku-4-5@20251001"}'

command -v jq >/dev/null || { echo "anomaly: jq not found" >&2; exit 1; }
[ -f "$SETTINGS" ] || { echo "anomaly: $SETTINGS missing" >&2; exit 1; }

# ── detection ─────────────────────────────────────────────────────────────────

current_mode() {
  local vertex base_url
  vertex=$(jq -r '.env.CLAUDE_CODE_USE_VERTEX // empty' "$SETTINGS")
  base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$SETTINGS")
  if [ "$vertex" = "1" ]; then
    echo vertex
  elif echo "$base_url" | grep -qi "openrouter"; then
    echo openrouter
  else
    echo sub
  fi
}

# ── helpers ───────────────────────────────────────────────────────────────────

# Atomic settings rewrite: backup → temp → mv.
apply_env() {
  local newenv="$1" tmp
  cp "$SETTINGS" "$SETTINGS.bak"
  tmp=$(mktemp)
  jq --argjson e "$newenv" '.env = $e' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
}

# Read OpenRouter key from opencode auth file.
openrouter_key() {
  [ -f "$OPENCODE_AUTH" ] && jq -r '.openrouter.key // empty' "$OPENCODE_AUTH" || true
}

# ── providers ─────────────────────────────────────────────────────────────────

to_sub() {
  mkdir -p "$PROFILE_DIR"
  local cur
  cur=$(current_mode)
  # Snapshot the current provider env before wiping it.
  [ "$cur" != "sub" ] && jq '.env' "$SETTINGS" > "$PROFILE_DIR/$cur.json"
  apply_env "$SUB_ENV"
  echo "Claude Code → Anthropic subscription."
}

to_vertex() {
  local penv profile="$PROFILE_DIR/vertex.json"
  if [ -f "$profile" ]; then
    penv=$(cat "$profile")
  else
    penv="$DEFAULT_VERTEX_ENV"
    echo "No vertex snapshot found; using built-in default."
  fi
  apply_env "$penv"
  echo "Claude Code → Vertex AI."
}

to_openrouter() {
  local key model or_env
  key=$(openrouter_key)
  [ -z "$key" ] && { echo "anomaly: no OpenRouter key in $OPENCODE_AUTH" >&2; exit 1; }
  # Override default model via env var if needed.
  model="${CLAUDE_CONFIGURE_OR_MODEL:-z-ai/glm-5.2}"
  or_env=$(jq -n \
    --arg k "$key" \
    --arg m "$model" \
    '{
      ANTHROPIC_BASE_URL: "https://openrouter.ai/api",
      ANTHROPIC_AUTH_TOKEN: $k,
      ANTHROPIC_API_KEY: "",
      ANTHROPIC_MODEL: $m,
      CLAUDE_CODE_MAX_CONTEXT_TOKENS: "1000000"
    }')
  apply_env "$or_env"
  echo "Claude Code → OpenRouter ($model)."
}

# ── status ────────────────────────────────────────────────────────────────────

status() {
  echo "mode: $(current_mode)"
  echo ""
  echo "settings env (secrets redacted):"
  jq '.env | to_entries | map(
    if (.key | test("_(KEY|TOKEN|SECRET)$"; "i"))
    then .value = "***"
    else .
    end
  ) | from_entries' "$SETTINGS"
}

# ── interactive picker ────────────────────────────────────────────────────────

PROVIDERS=("sub" "vertex" "openrouter")
DESCRIPTIONS=("sub       — Anthropic subscription (direct billing)" "vertex    — Google Vertex AI" "openrouter — OpenRouter proxy (z-ai/glm-5.2 default)")

pick_provider() {
  if command -v fzf >/dev/null 2>&1; then
    printf '%s\n' "${DESCRIPTIONS[@]}" \
      | fzf --prompt="provider> " --height=6 --border --no-info \
      | awk '{print $1}'
  else
    echo "Select provider:" >&2
    select desc in "${DESCRIPTIONS[@]}"; do
      [ -n "$desc" ] && { echo "$desc" | awk '{print $1}'; return; }
    done
  fi
}

# ── dispatch ──────────────────────────────────────────────────────────────────

dispatch() {
  case "$1" in
    sub|subscription|anthropic) to_sub ;;
    vertex)                     to_vertex ;;
    openrouter|or)              to_openrouter ;;
    status)                     status; exit 0 ;;
    -h|--help|help)
      echo "usage: claude-configure [sub|vertex|openrouter|status|-h]"
      echo "  no args — interactive provider picker"
      exit 0 ;;
    *) echo "anomaly: unknown arg '$1'" >&2; exit 1 ;;
  esac
  echo "Restart Claude Code for the change to take effect."
}

# ── main ──────────────────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
  provider=$(pick_provider)
  [ -z "$provider" ] && exit 0
  dispatch "$provider"
else
  dispatch "$1"
fi
