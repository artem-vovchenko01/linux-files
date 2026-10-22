# Knowledge Base — linux-files

Durable, repo-specific knowledge for AI agents. Stable facts only — setup
details, decisions, and gotchas future sessions will need. Update sections in
place; do not append dated logs or session chatter. Never store secrets, tokens,
or one-time links.

## Setup & Deployment

- `setup.sh` is the primary maintained workflow: it symlinks `dotfiles/` into
  `~/.config/` and `~/`. Idempotent — safe to re-run. It also recreates
  `~/g/<name>.git` aliases into `~/DATA/local-git` and adds a missing git
  remote `local` on cockpit-core / obsidian-personal / obsidian-work when those
  trees already have `.git`. It does not `git init` a tree with no `.git`.
- Each agent hub owns one `skills/` source directory. Claude Code, Codex, and
  OpenCode use project-local compatibility links under `.claude/skills/`,
  `.agents/skills/`, and `.opencode/skills/`. `setup.sh` exposes both hubs to
  Hermes globally. OpenClaw loads the two source directories directly.
- `my-git-os/` is archived/legacy and not the primary path.
- `setup.sh` and the work setup (`~/obsidian/obsidian-work/.ai/setup.sh`)
  share `setup-lib.sh` (ask, link, package helpers). Everything EPAM (work
  git identity, GCM, GlobalProtect, az/gcloud/aws/databricks, logins, ADO
  repo clones into `~/EPAM/<project>/<repo>`, local VMs, EPAM services) lives
  in the work setup; `setup.sh` calls it as its last step.
- `cmds` (`scripts/cmds.sh`, linked into `~/.local/bin`) is the fuzzy menu of
  all scripts. Folders come from `scripts/cmds.sources`, which includes the
  work hub's `.ai/cmds.sources`. A `# menu: <text>` line sets a script's
  description; `.menu_config` `IGNORE=` hides names, as for `menu.sh`.

## Environment

- The laptop runs Fedora (GNOME) and moves to Omarchy 4. Omarchy 4 owns
  `~/.config/hypr/*.lua`, its Quickshell desktop (bar, notifications, idle,
  lock), the terminal, tmux and nvim configs. `omarchy-font-set` rewrites
  `~/.config/fontconfig/fonts.conf`, so never link that file on Omarchy.
  The old `hyprland.conf`, waybar, mako, wofi and dunst configs serve only a
  hand-made Hyprland setup outside Omarchy.
- Omarchy's firewall is ufw with all incoming blocked except LocalSend.
  `setup.sh` offers Syncthing (private nets only), tailscale0 and ssh rules.
- This repo is public on GitHub. Work-only files live elsewhere:
  `~/.gitconfig-work` in `~/DATA/work-resources/GENERAL/gitconfig-work`, the
  EPAM user units in `~/obsidian/obsidian-work/.ai/epam/systemd/`.

## Gotchas

- Syncthing hub `.stignore` files contain `#include .stglobalignore`, and
  that file only arrives by sync. On a fresh machine the missing include puts
  the folder in an error state, so it never syncs: comment the line out until
  `.stglobalignore` arrives, then put it back.
- Claude login addresses live in `ai/private/account-emails.md`. That
  directory is gitignored. The tracked rule is
  `ai/global-instructions/alt-accounts.md`, and it names no address.

- 2026-10-22: Work hub moved from Logseq to Obsidian (/home/artem/obsidian/obsidian-work, Syncthing folder obsidian-work, bare repo ~/DATA/local-git/obsidian-work.git). setup.sh now aliases ~/g/obsidian-work.git, adds its `local` remote, and links work skills from ~/obsidian/obsidian-work/.agents/skills. Older logseq-work mentions remain in AGENT_INSTRUCTIONS.md, ai/CLAUDE_GLOBAL_CONFIG.md, ai/global-instructions/{grok-bot,knowledge-sources}.md, skills/grok-bot-delegator/SKILL.md and scripts/vm/vm.sh pending review.
