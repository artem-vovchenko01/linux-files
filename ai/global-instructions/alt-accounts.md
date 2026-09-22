# Alternate accounts for side agents

## Opus subagents: run on the alternate Pro account (Claude Code only)

I keep two Claude subscriptions: Max (the main login in `~/.claude` — needed for Fable 5) and Pro (logged in under `~/.claude-alt`), bought so that Opus side agents stop eating the Max session window. The two addresses are in `ai/private/account-emails.md` (gitignored, this machine only). Native subagents (Agent tool) always bill the parent session's account — there is no per-agent auth — so the routing is:

- **Any side agent that would run on Opus** (mechanical workers, test agents, PR reviewer/verifier agents, log scrapers, bulk edits) runs as a **headless subprocess billed to the Pro account**: `claude-alt -p ...` (wrapper in `~/linux-files/scripts/ai/claude-billing/`, on PATH; it sets `CLAUDE_CONFIG_DIR=$HOME/.claude-alt` and scrubs env vars that would override the OAuth login).
- **Fable-grade agents** (judgment-critical work needing the top model) stay native on the Max session. Harness-structural agents that cannot be subprocessed (plan-mode Explore/Plan agents, forks) also stay native.

Invocation recipe — keep it as close to native as possible:
1. Write the cold-start brief to a scratchpad file and pipe it via stdin: `claude-alt -p < brief.md` (avoids shell-quoting bugs). Run with cwd set to the target repo; use `--add-dir` for extra paths.
2. Ask for parseable output: `--output-format json` (read `result`, `is_error`, `session_id`), plus `--json-schema` when structured findings are wanted.
3. Permissions: the wrapper passes `--dangerously-skip-permissions` itself, so every `claude-alt` session, interactive or headless, runs in full bypass and no flag is needed. `~/.claude-alt/settings.json` also sets `permissions.defaultMode: "bypassPermissions"`, but that is only a backstop — Claude Code offers once to move a non-auto `defaultMode` to auto mode and rewrites the file if accepted, which is why the flag is the real guarantee. Test agents work in a throwaway worktree or scratch dir and never commit. Read-only verifiers may get a restricted `--tools` set as a guardrail, but not at the cost of blocking their work.
4. Long runs go through background execution with a generous timeout. On transient failure retry once, resuming with `--resume <session_id>` instead of restarting. Never use `--bare` (it disables OAuth login reading).
5. If the Pro account is unavailable (session/rate limit, auth lapse), fall back to a native Opus subagent on the Max account and disclose the fallback in the report.
6. Every final report names each side agent, its model, and which account it billed (`pro-alt` vs `max-native`).

If the Pro login lapses, I re-login with `claude-alt auth login --email <Pro address from ai/private/account-emails.md>` (prompt me; never assume the credential).

For a one-off interactive session billed to the Pro account, the command is `claude-alternate-sub-billing` (same wrapper, user-facing name). It touches nothing in `~/.claude`, so there is nothing to switch back.

Codex and Grok have the same split, in `~/linux-files/scripts/ai/alt-accounts/`: `codex-alt` runs on a second ChatGPT account (`CODEX_HOME=~/.codex-alt`) and `grok-alt` on a second xAI account (`GROK_HOME=~/.grok-alt`). Both keep the primary `codex` / `grok` login untouched, scrub the API-key env vars that would outrank the stored login, and run with approvals off for the same unattended reason. Log each second account in once with `codex-alt login` / `grok-alt login`.

Only the login is per-account: all three wrappers point the alt home's session stores back at the primary home (`share-sessions.sh` in `~/linux-files/scripts/ai/alt-accounts/`, plus `CODEX_SQLITE_HOME` for Codex's thread database). A session started on either account is listed and resumable from both, so a side agent's work can be picked up in a normal `claude` / `codex` / `grok` session.
