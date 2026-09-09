# Knowledge Base — linux-files

Durable, repo-specific knowledge for AI agents. Stable facts only — setup
details, decisions, and gotchas future sessions will need. Update sections in
place; do not append dated logs or session chatter. Never store secrets, tokens,
or one-time links.

## Setup & Deployment

- `setup.sh` is the primary maintained workflow: it symlinks `dotfiles/` into
  `~/.config/` and `~/`. Idempotent — safe to re-run.
- Each agent hub owns one `skills/` source directory. Claude Code, Codex, and
  OpenCode use project-local compatibility links under `.claude/skills/`,
  `.agents/skills/`, and `.opencode/skills/`. `setup.sh` exposes both hubs to
  Hermes globally. OpenClaw loads the two source directories directly.
- `my-git-os/` is archived/legacy and not the primary path.

## Environment

- Target platform: Arch Linux (pacman). Primary WM: Hyprland (Wayland); Sway
  configs exist as an alternative.

## Gotchas

_(none recorded yet)_
