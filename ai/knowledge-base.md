# Knowledge Base — linux-files

Durable, repo-specific knowledge for AI agents. Stable facts only — setup
details, decisions, and gotchas future sessions will need. Update sections in
place; do not append dated logs or session chatter. Never store secrets, tokens,
or one-time links.

## Setup & Deployment

- `setup.sh` is the primary maintained workflow: it symlinks `dotfiles/` into
  `~/.config/` and `~/`. Idempotent — safe to re-run. It also recreates
  `~/g/<name>.git` aliases into `~/DATA/local-git` and adds a missing git
  remote `local` on cockpit-core / logseq-personal / logseq-work when those
  trees already have `.git`. It does not `git init` a tree with no `.git`.
- Each agent hub owns one `skills/` source directory. Claude Code, Codex, and
  OpenCode use project-local compatibility links under `.claude/skills/`,
  `.agents/skills/`, and `.opencode/skills/`. `setup.sh` exposes both hubs to
  Hermes globally. OpenClaw loads the two source directories directly.
- `my-git-os/` is archived/legacy and not the primary path.

## Environment

- Target platform: Arch Linux (pacman). Primary WM: Hyprland (Wayland); Sway
  configs exist as an alternative.

## Gotchas

- Claude login addresses live in `ai/private/account-emails.md`. That
  directory is gitignored. The tracked rule is
  `ai/global-instructions/alt-accounts.md`, and it names no address.
