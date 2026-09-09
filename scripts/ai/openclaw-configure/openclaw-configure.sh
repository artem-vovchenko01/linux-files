#!/bin/bash

# openclaw-configure — pick OpenClaw models with fzf, keeping audio separate.
#
# Modes (pass as first arg, or pick interactively with no arg):
#   text   — switch the primary reasoning/coding model (agents.defaults.model).
#            Picks from the FULL catalog (`models list --all`): every provider,
#            incl. native anthropic/*, not just the already-configured ones.
#   image  — switch the vision model used when the text model lacks image input
#   audio  — configure voice: TTS output (on/off, engine, voice, when) + STT,
#            plus re-applying the talk realtime endpoint patch after an upgrade
#   status — show current text / image / audio state
#
# Why split audio out: text/image switches go through `openclaw models set` and
# `set-image`, which only rewrite model.primary / imageModel.primary. They never
# touch tools.media.audio (transcription) or talk.* (realtime voice), so
# swapping the chat model can't silently change the phone's voice pipeline.
# Everything audio lives in the `audio` mode on purpose.

set -euo pipefail

OC="$(command -v openclaw || true)"
[ -n "$OC" ] || { echo "anomaly: openclaw not on PATH" >&2; exit 1; }
command -v jq >/dev/null || { echo "anomaly: jq not found" >&2; exit 1; }

CONFIG="$HOME/.openclaw/openclaw.json"

# openclaw prefixes JSON output with doctor/migration noise on stdout.
# Reprint from the first line that starts a JSON value to the end.
ocjson() { "$OC" "$@" 2>/dev/null | sed -n '/^[[{]/,$p'; }

# pick — read display lines on stdin, return the first whitespace field of the
# chosen one. Every value we pick (model key, provider, voice, keyword) is a
# single token, so first-field extraction is safe. fzf when present, else select.
pick() {
  local prompt="$1" input
  input="$(cat)"
  [ -z "$input" ] && return 0
  if command -v fzf >/dev/null 2>&1; then
    printf '%s\n' "$input" \
      | fzf --prompt="$prompt> " --height=15 --border --no-info \
      | awk '{print $1}'
  else
    echo "$prompt:" >&2
    local IFS=$'\n' line
    select line in $input; do
      [ -n "$line" ] && { echo "$line" | awk '{print $1}'; return; }
    done
  fi
}

k() { printf '%dk' "$(( $1 / 1000 ))"; }  # bytes-ish ctx -> "200k"

# ── ollama workhorse availability (the "I'm ChatGPT" trap) ────────────────────
# OpenClaw's ollama-cloud/* models resolve through the LOCAL ollama server (a
# thin proxy to Ollama Cloud). A model works only if it has been pulled there
# (`ollama list` shows `<name>:cloud`). If the agent's primary model isn't pulled,
# reasoning / talk agent-consult calls silently fail and voice falls back to the
# OpenAI realtime model — the user hears "I'm ChatGPT" instead of the chosen
# brain. We can't pull for you (needs your ollama auth); we detect it and print
# the exact `ollama pull` to run.
OLLAMA_API="${OLLAMA_HOST:-http://127.0.0.1:11434}"
case "$OLLAMA_API" in http*) ;; *) OLLAMA_API="http://$OLLAMA_API" ;; esac

ollama_tags() {
  curl -fsS --max-time 3 "$OLLAMA_API/api/tags" 2>/dev/null \
    | jq -r '.models[].name' 2>/dev/null || true
}

# Echo the bare model name to look up on the server for an ollama model id,
# else nothing (non-ollama ids need no ollama check).
ollama_name() { case "$1" in ollama-cloud/*|ollama/*) echo "${1#*/}";; esac; }

# Status line(s) for one OpenClaw model id. Non-zero if it's an un-pulled ollama
# model. Prints nothing for non-ollama ids (openai etc. need no local pull).
ollama_check_model() {
  local label="$1" id="$2" name tags t
  name=$(ollama_name "$id"); [ -z "$name" ] && return 0
  tags=$(ollama_tags)
  if [ -z "$tags" ]; then
    echo "  $label: ollama unreachable ($OLLAMA_API) — can't verify $id"
    return 0
  fi
  while IFS= read -r t; do
    [ "$t" = "$name" ] && { echo "  $label: OK ($id)"; return 0; }
    case "$t" in "$name":*) echo "  $label: OK ($id)"; return 0 ;; esac
  done <<<"$tags"
  echo "  $label: NOT PULLED — $id absent on ollama server; calls will fall back"
  echo "     fix: ollama pull $name:cloud  (then: openclaw gateway restart)"
  return 1
}

# ── model picking (full catalog, incl. Anthropic & every other provider) ──────
# `models list` defaults to *configured* models only. We pass --all so the picker
# offers the whole catalog: native anthropic/*, github-copilot/*, mistral/* etc.
# — not just what already has credentials. Each model carries an `available`
# flag (true when its provider is authenticated / usable right now); we surface
# it as a ready|needs-auth column and sort ready-first so the usable models
# (incl. claude-cli/* Claude, which rides your local Claude CLI) float to the top.

# Warn — after a `set` — if the chosen model won't actually run yet: an un-pulled
# ollama model (the "I'm ChatGPT" trap) or an unauthenticated provider. $2 is the
# catalog JSON already fetched by the caller, so we don't re-query.
post_set_hint() {
  local sel="$1" catalog="$2" provider="${sel%%/*}" warn avail
  # ollama models: verify the tag is pulled on the local ollama server.
  warn=$(ollama_check_model "ollama" "$sel")
  [ -n "$warn" ] && printf '%s\n' "$warn"
  [ -n "$(ollama_name "$sel")" ] && return 0
  # Non-ollama providers: if the catalog marks it unavailable, it needs auth.
  avail=$(printf '%s' "$catalog" | jq -r --arg k "$sel" \
      '.models[] | select(.key==$k) | .available')
  [ "$avail" = "true" ] && return 0
  echo "  NOTE: provider '$provider' isn't authenticated — model set, but calls"
  echo "        fail until you add credentials:"
  echo "          openclaw models auth login --provider $provider"
  echo "        (claude-cli/* rides the local Claude CLI; anthropic/* wants an API key)"
}

do_text() {
  local catalog sel
  catalog=$(ocjson models list --all --json)
  sel=$(printf '%s' "$catalog" \
    | jq -r '.models
        | sort_by((.available|not), .key)[]
        | [.key,
           (if .available then "ready" else "needs-auth" end),
           .input,
           ((.contextWindow/1000|floor|tostring)+"k"),
           ((.tags//[])|join(","))] | @tsv' \
    | column -t -s $'\t' | pick 'text model')
  [ -z "$sel" ] && { echo "cancelled."; return 0; }
  "$OC" models set "$sel" >/dev/null
  echo "text model -> $sel   (audio + talk untouched)"
  post_set_hint "$sel" "$catalog"
}

# ── image / vision model ────────────────────────────────────────────────────

do_image() {
  local catalog sel
  catalog=$(ocjson models list --all --json)
  sel=$(printf '%s' "$catalog" \
    | jq -r '.models
        | map(select((.input|test("image")) or ((.tags//[])|index("image"))))
        | sort_by((.available|not), .key)[]
        | [.key,
           (if .available then "ready" else "needs-auth" end),
           .input,
           ((.contextWindow/1000|floor|tostring)+"k"),
           ((.tags//[])|join(","))] | @tsv' \
    | column -t -s $'\t' | pick 'image (vision) model')
  [ -z "$sel" ] && { echo "cancelled."; return 0; }
  "$OC" models set-image "$sel" >/dev/null
  echo "image model -> $sel   (text + audio untouched)"
  post_set_hint "$sel" "$catalog"
}

# ── audio: TTS (voice out) + STT (voice in) ─────────────────────────────────

audio_provider() {
  local p
  p=$(ocjson infer tts status --json \
    | jq -r '.providerStates[] | select(.configured) | .id' | pick 'tts engine')
  [ -z "$p" ] && { echo "cancelled."; return 0; }
  "$OC" infer tts set-provider --provider "$p" >/dev/null 2>&1
  echo "tts engine -> $p"
}

audio_voice() {
  local prov voice
  prov=$(ocjson infer tts status --json | jq -r '.provider // empty')
  [ -z "$prov" ] && { echo "anomaly: no active tts provider" >&2; return 1; }
  voice=$(ocjson infer tts voices --provider "$prov" --json \
    | jq -r '(if type=="array" then . else .voices end)[]
        | "\(.id)\t\(.gender // "?")\t\(.locale // "?")"' \
    | column -t -s $'\t' | pick "$prov voice")
  [ -z "$voice" ] && { echo "cancelled."; return 0; }
  # Preview so you actually hear it before committing.
  local tmp; tmp=$(mktemp --suffix=.mp3)
  if "$OC" infer tts convert --voice "$voice" \
        --text "This is $voice speaking." --output "$tmp" >/dev/null 2>&1; then
    command -v mpv >/dev/null && mpv --really-quiet "$tmp" >/dev/null 2>&1 || true
  fi
  rm -f "$tmp"
  # Persist as the default persona. speakerVoiceId is the key the TTS runtime
  # resolves first (speakerVoiceId ?? voiceId).
  "$OC" config set messages.tts.personas.default \
    "{\"provider\":\"$prov\",\"providers\":{\"$prov\":{\"speakerVoiceId\":\"$voice\"}}}" \
    --strict-json >/dev/null
  "$OC" config set messages.tts.persona default >/dev/null
  echo "tts voice -> $voice   (restart gateway to apply: openclaw gateway restart)"
}

audio_auto() {
  local m
  m=$(printf '%s\n' \
      "always    speak every reply" \
      "inbound   speak only replies to voice messages" \
      "tagged    speak only when the reply is tagged for voice" \
      "off       never speak (text only)" | pick 'speak when')
  [ -z "$m" ] && { echo "cancelled."; return 0; }
  "$OC" config set messages.tts.auto "$m" >/dev/null
  echo "speak-replies -> $m"
}

audio_stt() {
  local m
  m=$(printf '%s\n' \
      "gpt-4o-transcribe        accurate, default" \
      "gpt-4o-mini-transcribe   cheaper, faster" \
      "whisper-1                legacy whisper" | pick 'transcription model')
  [ -z "$m" ] && { echo "cancelled."; return 0; }
  "$OC" config set tools.media.audio.models \
    "[{\"provider\":\"openai\",\"model\":\"$m\",\"capabilities\":[\"audio\"]}]" \
    --strict-json >/dev/null
  echo "transcription model -> openai/$m"
}

# ── talk voice repair (endpoint patch + trusted-proxy config) ────────────────
# Two independent things break realtime voice (talk); the `patch` action fixes
# both and reports which was needed:
#  1. dist endpoint — OpenAI removed POST /v1/realtime/transcription_sessions
#     (404); OpenClaw's dist still mints the STT secret there, so talk dies with
#     "Unknown transcription Talk session". An `openclaw` npm reinstall REVERTS
#     the dist, so this one must be re-applied after every upgrade.
#  2. trustedProxies — behind `tailscale serve` the gateway is proxied from
#     loopback; without gateway.trustedProxies it denies the phone "local" status
#     and talk stalls ("request timeout"). This lives in ~/.openclaw config so it
#     SURVIVES upgrades; we just verify/restore it so one action fixes talk.
DEAD_EP='realtime/transcription_sessions'

oc_dist() {
  local p root
  p=$(readlink -f "$OC" 2>/dev/null || true)
  p=${p%/*}
  if [ -n "$p" ] && [ -d "$p/dist" ]; then echo "$p/dist"; return 0; fi
  root=$(npm root -g 2>/dev/null || true)
  if [ -n "$root" ] && [ -d "$root/openclaw/dist" ]; then
    echo "$root/openclaw/dist"
  fi
  return 0
}

# Print the dist .js still on the dead route (empty if patched / not found).
# Matches by content, not filename — the bundle's hashed name changes on upgrade.
talk_dead_file() {
  local dist; dist=$(oc_dist)
  [ -n "$dist" ] || return 0
  grep -rIl --include='*.js' --exclude='*.orig' "$DEAD_EP" "$dist" 2>/dev/null \
    | head -1 || true
}

patch_endpoint() {
  local f; f=$(talk_dead_file)
  if [ -z "$f" ]; then
    echo "talk endpoint: OK (GA client_secrets; nothing to patch)"
    return 0
  fi
  echo "talk endpoint: NEEDS PATCH"
  echo "  file : $f"
  echo "  why  : OpenAI removed POST /v1/$DEAD_EP (404); realtime voice STT"
  echo "         dies with 'Unknown transcription Talk session' until repointed."
  # Only touch the exact known-bad shape; refuse if OpenClaw's internals moved.
  local nurl nbody
  nurl=$(grep -c "$DEAD_EP" "$f" || true)
  nbody=$(grep -c 'body: params.session,' "$f" || true)
  if [ "$nurl" != 1 ] || [ "$nbody" != 1 ]; then
    echo "anomaly: unexpected code shape (url x$nurl, body x$nbody)." >&2
    echo "  OpenClaw changed — patch by hand or check for an upstream fix." >&2
    return 1
  fi
  printf 'apply patch now? [y/N] '
  local ans; read -r ans
  case "$ans" in [yY]*) ;; *) echo "skipped."; return 0 ;; esac
  cp -n "$f" "$f.orig"
  # 1) dead route -> GA route; 2) GA route needs the { session } body wrapper.
  sed -i "s#$DEAD_EP#realtime/client_secrets#" "$f"
  sed -i 's#body: params.session,#body: { session: params.session },#' "$f"
  if grep -q "$DEAD_EP" "$f" || grep -q 'body: params.session,' "$f"; then
    echo "anomaly: patch did not apply cleanly; restoring backup" >&2
    cp -f "$f.orig" "$f"; return 1
  fi
  echo "patched -> $f   (backup: $f.orig)"
  echo "restart gateway to apply: openclaw gateway restart"
}

# trustedProxies half of talk repair. Returns 0 (true) when it IS needed but
# missing: behind `tailscale serve`/`funnel` the gateway is proxied from loopback,
# and without gateway.trustedProxies it denies the phone "local" status so talk
# stalls ("request timeout"). This lives in ~/.openclaw config, so it survives
# npm upgrades (unlike the dist endpoint patch).
tp_needed() {
  local mode tp
  mode=$(jq -r '.gateway.tailscale.mode // "off"' "$CONFIG")
  case "$mode" in serve|funnel) ;; *) return 1 ;; esac
  tp=$(jq -r '(.gateway.trustedProxies // []) | length' "$CONFIG")
  [ "$tp" -eq 0 ]
}

patch_trustedproxies() {
  if ! tp_needed; then
    echo "talk trustedProxies: OK (set, or not behind tailscale serve)"
    return 0
  fi
  echo "talk trustedProxies: NEEDS SET"
  echo "  why : tailscale serve proxies from loopback; without trustedProxies the"
  echo "        gateway denies the phone 'local' and talk stalls (request timeout)."
  printf 'set gateway.trustedProxies=[127.0.0.1,::1] now? [y/N] '
  local ans; read -r ans
  case "$ans" in [yY]*) ;; *) echo "skipped."; return 0 ;; esac
  "$OC" config set gateway.trustedProxies '["127.0.0.1","::1"]' \
    --strict-json >/dev/null
  echo "set -> restart gateway to apply: openclaw gateway restart"
}

# ── talk consult routing (the "I'm ChatGPT, your voice companion" trap) ───────
# Distinct from the workhorse being un-pulled: here the agent consult never fires
# at all, so the realtime provider (gpt-realtime) answers in its OWN persona —
# "I'm ChatGPT, your voice companion" — instead of your OpenClaw/Claude brain.
# Two talk.realtime keys govern it (openclaw config schema):
#   brain=agent-consult                use the Gateway agent (your Claude brain)
#   consultRouting=force-agent-consult route EVERY final transcript through it,
#                                      so the provider can't reply as itself
# The defaults (brain unset, consultRouting=provider-direct) preserve provider
# replies → the ChatGPT identity leaks. Forcing consult adds a little latency per
# turn (each reply waits on a full brain consult) but is what makes voice = Claude.
talk_consult_needs_fix() {
  local brain routing
  brain=$(jq -r '.talk.realtime.brain // ""' "$CONFIG")
  routing=$(jq -r '.talk.realtime.consultRouting // ""' "$CONFIG")
  [ "$brain" != "agent-consult" ] || [ "$routing" != "force-agent-consult" ]
}

patch_talk_consult() {
  if ! talk_consult_needs_fix; then
    echo "talk consult: OK (brain=agent-consult, consultRouting=force-agent-consult)"
    return 0
  fi
  local brain routing
  brain=$(jq -r '.talk.realtime.brain // "(unset)"' "$CONFIG")
  routing=$(jq -r '.talk.realtime.consultRouting // "(unset → provider-direct)"' "$CONFIG")
  echo "talk consult: NEEDS FIX — voice can answer as 'ChatGPT, your voice companion'"
  echo "  brain         : $brain   (want: agent-consult)"
  echo "  consultRouting: $routing   (want: force-agent-consult)"
  echo "  why : without these the gpt-realtime model replies in its own persona"
  echo "        instead of deferring every turn to your OpenClaw/Claude brain."
  printf 'set brain=agent-consult + consultRouting=force-agent-consult now? [y/N] '
  local ans; read -r ans
  case "$ans" in [yY]*) ;; *) echo "skipped."; return 0 ;; esac
  "$OC" config set talk.realtime.brain agent-consult >/dev/null
  "$OC" config set talk.realtime.consultRouting force-agent-consult >/dev/null
  echo "set -> restart gateway to apply: openclaw gateway restart"
}

# One action repairs every talk failure mode and reports which was needed.
audio_patch() {
  patch_endpoint
  echo
  patch_trustedproxies
  echo
  patch_talk_consult
}

audio_status() {
  local ts
  ts=$(ocjson infer tts status --json)
  echo "voice output (TTS):"
  echo "$ts" | jq -r '"  enabled : \(.enabled)\n  engine  : \(.provider)\n  when    : \(.auto)\n  persona : \(.persona // "(provider default voice)")"'
  echo "voice input (STT / transcription):"
  jq -r '"  model   : \(.tools.media.audio.models[0].provider)/\(.tools.media.audio.models[0].model)"' "$CONFIG" 2>/dev/null || echo "  model   : (unset)"
  echo "talk (realtime voice call):"
  jq -r '"  provider: \(.talk.provider // "(none)")\n  model   : \(.talk.realtime.model // "gpt-realtime-2 (default)")"' "$CONFIG" 2>/dev/null
  # talk brain = the reasoning workhorse (agents.defaults.model.primary) the
  # realtime voice defers to via agent-consult. If it's an un-pulled ollama
  # model the consult fails and voice answers as "ChatGPT" — surface that here.
  local brain avail
  brain=$(jq -r '.agents.defaults.model.primary // empty' "$CONFIG")
  echo "  brain   : ${brain:-(unset)}   (reasoning workhorse for consult)"
  avail=$(ollama_check_model "brain" "$brain" || true)
  [ -n "$avail" ] && printf '%s\n' "$avail"
  # consult routing: is every turn forced through that brain, or can the realtime
  # provider answer as itself ("I'm ChatGPT, your voice companion")?
  local bmode routing
  bmode=$(jq -r '.talk.realtime.brain // "(unset)"' "$CONFIG")
  routing=$(jq -r '.talk.realtime.consultRouting // "(unset→provider-direct)"' "$CONFIG")
  if talk_consult_needs_fix; then
    echo "  consult : NEEDS FIX — brain=$bmode routing=$routing (voice may answer as ChatGPT)"
  else
    echo "  consult : OK — brain=agent-consult, force-agent-consult (every turn → your brain)"
  fi
  if [ -n "$(talk_dead_file)" ]; then
    echo "  endpoint: NEEDS PATCH (removed transcription_sessions route present)"
  else
    echo "  endpoint: OK (GA client_secrets)"
  fi
  if tp_needed; then
    echo "  proxies : trustedProxies NOT SET (talk stalls behind tailscale serve)"
  else
    echo "  proxies : OK"
  fi
}

do_audio() {
  local action
  [ -n "$(talk_dead_file)" ] && \
    echo "⚠ talk voice endpoint needs patching — pick 'patch' below."
  tp_needed && \
    echo "⚠ talk trustedProxies not set — pick 'patch' below."
  talk_consult_needs_fix && \
    echo "⚠ talk consult not forced — voice may answer as ChatGPT; pick 'patch' below."
  action=$(printf '%s\n' \
      "on         turn voice output ON (enable TTS)" \
      "off        turn voice output OFF (disable TTS)" \
      "engine     choose the TTS voice engine (provider)" \
      "voice      choose + preview the TTS voice" \
      "when       when to speak replies (always/inbound/tagged/off)" \
      "stt        transcription (voice-in) model" \
      "patch      repair talk: endpoint + trustedProxies + consult routing" \
      "status     show current audio config" | pick 'audio')
  case "$action" in
    on)     "$OC" infer tts enable  >/dev/null && echo "voice output ENABLED"; ;;
    off)    "$OC" infer tts disable >/dev/null && echo "voice output DISABLED"; ;;
    engine) audio_provider ;;
    voice)  audio_voice ;;
    when)   audio_auto ;;
    stt)    audio_stt ;;
    patch)  audio_patch ;;
    status) audio_status ;;
    "")     echo "cancelled." ;;
    *)      echo "anomaly: unknown audio action '$action'" >&2; return 1 ;;
  esac
}

# ── status (top level) ──────────────────────────────────────────────────────

do_status() {
  local primary image avail
  primary=$(jq -r '.agents.defaults.model.primary // empty' "$CONFIG")
  image=$(jq -r '.agents.defaults.imageModel.primary // "(none)"' "$CONFIG")
  echo "text model  : ${primary:-(unset)}"
  echo "image model : $image"
  # Both are ollama-cloud/* here; verify each is actually pulled on the server.
  avail=$( ollama_check_model "text " "$primary" || true
           ollama_check_model "image" "$image"   || true )
  [ -n "$avail" ] && { echo "ollama availability:"; printf '%s\n' "$avail"; }
  echo ""
  audio_status
}

# ── dispatch ────────────────────────────────────────────────────────────────

dispatch() {
  case "$1" in
    text|model) do_text ;;
    image|vision) do_image ;;
    audio|voice) do_audio ;;
    status) do_status ;;
    -h|--help|help)
      echo "usage: openclaw-configure [text|image|audio|status]"
      echo "  no args — pick a mode interactively"
      echo "  text    — switch primary chat model, full catalog incl. anthropic"
      echo "            (leaves audio/talk alone)"
      echo "  image   — switch vision model, full catalog (leaves text/audio alone)"
      echo "  audio   — TTS voice output + STT transcription config"
      echo "  status  — show current model + audio state"
      ;;
    *) echo "anomaly: unknown mode '$1'" >&2; exit 1 ;;
  esac
}

if [ $# -eq 0 ]; then
  mode=$(printf '%s\n' \
      "text     switch the chat/reasoning model" \
      "image    switch the vision model" \
      "audio    voice output + transcription" \
      "status   show current state" | pick 'configure')
  [ -z "$mode" ] && exit 0
  dispatch "$mode"
else
  dispatch "$1"
fi
