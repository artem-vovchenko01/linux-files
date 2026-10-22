# Alternate accounts for side agents

## Opus side agents: run on the second Claude account (Claude Code only)

I keep two Claude Pro subscriptions: one logged in under `~/.claude`, the
other under `~/.claude-alt`. The second one exists so that side agents do not
eat the main session's 5-hour window. `agent-quota claude` shows which
address sits behind each home right now; the addresses have swapped before,
so do not hard-code them. Native subagents (Agent tool) always bill the
parent session's account (there is no per-agent auth), so the routing is:

- **Any side agent that would run on Opus** (mechanical workers, test agents,
  PR reviewer and verifier agents, log scrapers, bulk edits) runs as a
  **headless subprocess on the second account**: `claude-alt -p ...`
  (wrapper in `~/linux-files/scripts/ai/claude-billing/`, on PATH; it sets
  `CLAUDE_CONFIG_DIR=$HOME/.claude-alt` and unsets the env vars that would
  override the OAuth login or pin models).
- **Judgment-critical agents** that need the session's own top model stay
  native. So do harness-structural agents that cannot run as a subprocess
  (plan-mode Explore/Plan agents, forks).
- **A session that already runs on `~/.claude-alt`** (the shell shows it in
  `agent-quota claude`) spawns native side agents; they bill the same
  account either way.

Invocation recipe:

1. Write the cold-start brief to a scratchpad file and pipe it through
   stdin: `claude-alt -p < brief.md` (no shell-quoting bugs). Run with cwd
   set to the target repo; use `--add-dir` for extra paths.
2. Ask for parseable output: `--output-format json` (read `result`,
   `is_error`, `session_id`; `modelUsage` shows the model actually used),
   plus `--json-schema` when you want structured findings.
3. Permissions: the wrapper passes `--dangerously-skip-permissions` itself,
   so every `claude-alt` session runs in full bypass. The
   `permissions.defaultMode: "bypassPermissions"` line in
   `~/.claude-alt/settings.json` is only a backstop: Claude Code offers once
   to move a non-auto `defaultMode` to auto mode and rewrites the file if
   accepted. Test agents work in a throwaway worktree or scratch dir and
   never commit. Read-only verifiers may get a restricted `--tools` set, but
   not at the cost of blocking their work.
4. Long runs go to background execution with a generous timeout. On a
   transient failure retry once with `--resume <session_id>` instead of
   restarting. Never use `--bare` (it disables OAuth login reading).
5. If the second account is unavailable (rate limit, auth lapse), fall back
   to a native Opus subagent and say so in the report.
6. Every final report names each side agent, its model, and the account it
   billed (`alt` or `native`).

If the second login lapses, ask me to re-login with
`claude-alt auth login --email <address>`. Take the address from
`agent-quota claude` or gitignored `~/linux-files/ai/private/account-emails.md`;
never guess a credential.

For a one-off interactive session on the second account, the command is
`claude-alternate-sub-billing` (same wrapper, user-facing name). It touches
nothing in `~/.claude`, so there is nothing to switch back.

## Codex and Grok

The same split lives in `~/linux-files/scripts/ai/alt-accounts/`:
`codex-alt` runs on a second ChatGPT account (`CODEX_HOME=~/.codex-alt`) and
`grok-alt` on a second xAI account (`GROK_HOME=~/.grok-alt`). Both keep the
primary `codex` / `grok` login untouched, unset the API-key env vars that
would outrank the stored login, and run with approvals off for the same
unattended reason. Log each second account in once with `codex-alt login` /
`grok-alt login`.

Only the login is per-account. Both homes of each CLI keep their session
stores as symlinks into `~/DATA/agentic-context` (see "Agent sessions and
memories" in the global index). The wrappers point the rest of the alt
home's machine-local state (prompt history, shell snapshots) back at the
primary home (`share-sessions.sh` in the same folder, plus
`CODEX_SQLITE_HOME` for Codex's thread database). A session started on
either account is listed and resumable from both, so a side agent's work
can be picked up in a normal `claude` / `codex` / `grok` session.
