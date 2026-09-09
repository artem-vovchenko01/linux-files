#!/bin/bash

# claude-configure — switch Claude Code between billing/routing backends.
# Providers: sub (Anthropic subscription), vertex (Google Vertex AI),
#            openrouter (OpenRouter proxy), ollama (local/cloud via LiteLLM).
#
# Provider env lives in ~/.claude/settings.json under .env.  This script
# rewrites that block atomically; each non-sub provider's env is snapshotted
# to ~/.claude/billing-profiles/<provider>.json for safe round-tripping.
#
# OpenRouter key is read from ~/.local/share/opencode/auth.json (.openrouter.key).
#
# Ollama: Claude Code only speaks the Anthropic /v1/messages API, which Ollama
# does not serve.  We bridge through a local LiteLLM proxy (a wildcard route
# ollama_chat/* so any pulled model works) on port 4001 — separate from the
# Vertex LiteLLM proxy on 4000.  Reuses the litellm-vertex venv + master key.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
PROFILE_DIR="$HOME/.claude/billing-profiles"
OPENCODE_AUTH="$HOME/.local/share/opencode/auth.json"
WORK_GCP_PROJECT_FILE="$HOME/.work-gcp-project-name"

# Ollama bridge plumbing.
OLLAMA_PORT=4001
OLLAMA_API="http://127.0.0.1:11434"
LITELLM_VENV="$HOME/.local/share/litellm-vertex/venv"
LITELLM_OLLAMA_CFG="$HOME/.config/litellm/ollama-config.yaml"
MASTER_KEY_FILE="$HOME/.config/litellm/.master_key"

# Subscription mode sets no model pins: the opus/sonnet aliases then resolve
# to the newest recommended models, and pinning would freeze them (that is
# what ANTHROPIC_DEFAULT_*_MODEL is for). Only the Vertex profile pins models.
SUB_ENV='{}'

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
  elif echo "$base_url" | grep -q ":$OLLAMA_PORT"; then
    echo ollama
  else
    echo sub
  fi
}

# ── helpers ───────────────────────────────────────────────────────────────────

default_vertex_env() {
  local project filter
  if [ ! -r "$WORK_GCP_PROJECT_FILE" ]; then
    echo "anomaly: $WORK_GCP_PROJECT_FILE missing" >&2
    return 1
  fi
  project=$(head -n 1 "$WORK_GCP_PROJECT_FILE")
  if [ -z "$project" ]; then
    echo "anomaly: $WORK_GCP_PROJECT_FILE is empty" >&2
    return 1
  fi
  filter='{
    CLAUDE_CODE_USE_VERTEX: "1",
    ANTHROPIC_VERTEX_PROJECT_ID: $project,
    CLOUD_ML_REGION: "global",
    ANTHROPIC_DEFAULT_SONNET_MODEL: "claude-sonnet-4-6",
    ANTHROPIC_DEFAULT_OPUS_MODEL: "claude-opus-4-8",
    ANTHROPIC_DEFAULT_HAIKU_MODEL: "claude-haiku-4-5@20251001"
  }'
  jq -cn --arg project "$project" "$filter"
}

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
    penv=$(default_vertex_env)
    echo "No vertex snapshot found; using the local project."
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

# ── ollama bridge helpers ──────────────────────────────────────────────────────

# Make sure `ollama serve` is reachable; start it detached if not.
ensure_ollama_up() {
  curl -sf -o /dev/null "$OLLAMA_API/api/tags" && return 0
  command -v ollama >/dev/null || { echo "anomaly: ollama not installed" >&2; exit 1; }
  echo "Starting ollama serve…" >&2
  nohup ollama serve >/dev/null 2>&1 &
  for _ in $(seq 1 20); do
    curl -sf -o /dev/null "$OLLAMA_API/api/tags" && return 0
    sleep 0.5
  done
  echo "anomaly: ollama did not come up on 11434" >&2; exit 1
}

# Write the wildcard LiteLLM config once (any pulled model routes through it).
write_ollama_cfg() {
  mkdir -p "$(dirname "$LITELLM_OLLAMA_CFG")"
  cat > "$LITELLM_OLLAMA_CFG" <<EOF
# LiteLLM proxy: bridges Anthropic /v1/messages -> Ollama (local or :cloud).
# Wildcard route — any model Claude Code asks for is forwarded to ollama_chat.
# Generated by claude-configure; edit there, not here.
model_list:
  - model_name: "*"
    litellm_params:
      model: "ollama_chat/*"
      api_base: $OLLAMA_API

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY

litellm_settings:
  drop_params: true
EOF
}

# Make sure the LiteLLM ollama proxy is listening on $OLLAMA_PORT.
ensure_ollama_proxy_up() {
  curl -sf -o /dev/null "http://127.0.0.1:$OLLAMA_PORT/health/liveliness" && return 0
  [ -x "$LITELLM_VENV/bin/litellm" ] || { echo "anomaly: litellm venv missing at $LITELLM_VENV" >&2; exit 1; }
  [ -f "$MASTER_KEY_FILE" ] || { echo "anomaly: $MASTER_KEY_FILE missing" >&2; exit 1; }
  write_ollama_cfg
  echo "Starting LiteLLM ollama proxy on :$OLLAMA_PORT…" >&2
  LITELLM_MASTER_KEY="$(cat "$MASTER_KEY_FILE")" \
    nohup "$LITELLM_VENV/bin/litellm" --config "$LITELLM_OLLAMA_CFG" \
      --host 127.0.0.1 --port "$OLLAMA_PORT" >/tmp/litellm-ollama.log 2>&1 &
  for _ in $(seq 1 30); do
    curl -sf -o /dev/null "http://127.0.0.1:$OLLAMA_PORT/health/liveliness" && return 0
    sleep 0.5
  done
  echo "anomaly: litellm ollama proxy did not come up (see /tmp/litellm-ollama.log)" >&2
  exit 1
}

# Pick an installed Ollama model. Honors $CLAUDE_CONFIGURE_OLLAMA_MODEL.
pick_ollama_model() {
  local override="${CLAUDE_CONFIGURE_OLLAMA_MODEL:-}"
  [ -n "$override" ] && { echo "$override"; return; }
  local models
  models=$(curl -sf "$OLLAMA_API/api/tags" | jq -r '.models[].name' 2>/dev/null)
  [ -z "$models" ] && { echo "anomaly: no ollama models installed (ollama pull <model>)" >&2; exit 1; }
  if [ "$(echo "$models" | wc -l)" -eq 1 ]; then
    echo "$models"; return
  fi
  if command -v fzf >/dev/null 2>&1; then
    echo "$models" | fzf --prompt="ollama model> " --height=10 --border --no-info
  else
    echo "Select ollama model:" >&2
    select m in $models; do [ -n "$m" ] && { echo "$m"; return; }; done
  fi
}

to_ollama() {
  ensure_ollama_up
  ensure_ollama_proxy_up
  local model key ol_env
  model=$(pick_ollama_model)
  [ -z "$model" ] && { echo "cancelled." >&2; exit 0; }
  key="$(cat "$MASTER_KEY_FILE")"
  ol_env=$(jq -n \
    --arg k "$key" \
    --arg m "$model" \
    --arg b "http://127.0.0.1:$OLLAMA_PORT" \
    '{
      ANTHROPIC_BASE_URL: $b,
      ANTHROPIC_AUTH_TOKEN: $k,
      ANTHROPIC_API_KEY: "",
      ANTHROPIC_MODEL: $m,
      ANTHROPIC_DEFAULT_OPUS_MODEL: $m,
      ANTHROPIC_DEFAULT_SONNET_MODEL: $m,
      ANTHROPIC_DEFAULT_HAIKU_MODEL: $m
    }')
  apply_env "$ol_env"
  echo "Claude Code → Ollama ($model) via LiteLLM :$OLLAMA_PORT."
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

PROVIDERS=("sub" "vertex" "openrouter" "ollama")
DESCRIPTIONS=("sub       — Anthropic subscription (direct billing)" "vertex    — Google Vertex AI" "openrouter — OpenRouter proxy (z-ai/glm-5.2 default)" "ollama    — local/cloud Ollama via LiteLLM (pick model)")

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
    ollama)                     to_ollama ;;
    status)                     status; exit 0 ;;
    -h|--help|help)
      echo "usage: claude-configure [sub|vertex|openrouter|ollama|status|-h]"
      echo "  no args — interactive provider picker"
      echo "  ollama  — starts ollama + LiteLLM proxy, then picks a model"
      echo "            (override model: CLAUDE_CONFIGURE_OLLAMA_MODEL=<name>)"
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
