# Agent Instructions — linux-files

> Shared instruction file for all AI agents. The same file is symlinked at the
> repo root as `CLAUDE.md` (Anthropic), `AGENTS.md` (OpenAI Codex), `GEMINI.md`
> (Google), and `GROK.md` (xAI). **Source of truth: `AGENT_INSTRUCTIONS.md`.**
> Edit it once — every agent sees the change. No per-agent cross-updating needed.

## Multi-Agent Collaboration

- This repository may be modified by multiple coding agents (Claude, Codex,
  Gemini, Grok). Expect concurrent edits and keep changes compatible across agent
  workflows.
- Don't overwrite other agents' work. Read before writing; check `git status` and
  `git log --oneline -10` for recent changes before major edits, and prefer
  appending over rewriting.
- All agent guidance lives in `AGENT_INSTRUCTIONS.md`. The four root files
  (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `GROK.md`) are symlinks to it, so a
  single edit keeps every agent aligned — do not recreate them as separate files.

## Durable Knowledge (`ai/knowledge-base.md`)

Persistent, repo-specific learnings live in `ai/knowledge-base.md`. When you
discover something future sessions will need — a non-obvious setup detail, a
stable decision, a gotcha about this machine or these dotfiles, why something is
done a certain way — record it there. Durable facts only: update the relevant
section in place, do not append dated logs or session chatter. Never store
secrets, tokens, or one-time links.

## Project Overview

Personal Linux dotfiles and automation repository for Arch Linux, centered around Hyprland (Wayland compositor) as the primary desktop environment. Contains configuration files for 25+ applications and 80+ utility scripts. The primary maintained workflow is `setup.sh`; `my-git-os` and Arch install flows are in archived legacy state.

## Key Commands

```bash
# Main workflow: deploy all configs (creates symlinks to ~/.config/*)
./setup.sh

# Archived legacy workflow: OS setup framework (interactive script picker)
bash my-git-os/main.sh

# Launch the wofi-based script menu (from within Hyprland)
bash scripts/menu.sh
```

There are no build, lint, or test commands — this is a collection of shell scripts and config files, not a compiled project.

## Architecture

### Dotfile Deployment
`setup.sh` creates symlinks from `dotfiles/` into `~/.config/` and `~/`. Configs live in the repo and are linked, not copied. It is designed to be idempotent (safe to run many times). This is the main maintained workflow. Adding a new config means adding the file under `dotfiles/<app>/` and a corresponding `ln -sf` line in `setup.sh`.

### Script Organization (`scripts/`)
Scripts are grouped by function: `admin/`, `devices/`, `media/`, `tiling-wm/`, `files/`, `pomodoro/`, `tool/`, `epam/`, etc. The wofi menu (`scripts/menu.sh`) provides a GUI launcher that recursively browses these directories. Per-directory `.menu_config` files control which scripts get a terminal (`SPAWN_TERMINAL=`) and which are hidden (`IGNORE=`).

### Archived OS Installation Framework (`my-git-os/`)
Multi-stage setup system:
- `lib/lib-root.sh` — core library with logging, package management, platform detection
- `base-scripts/00-base-script.sh` — foundation sourced by all other scripts
- `base-scripts/04-software.sh` — package installation
- `base-scripts/05-configs.sh` — config symlinking
- `additional-scripts/` — optional modules (environments, software, system)
- `main.sh` — entry point with interactive/non-interactive modes

The framework clones this repo to `~/.my-git-os/linux-files/` and operates from there. It is kept for archival/legacy use and is not the primary workflow.

### Tiling WM Scripts (`scripts/tiling-wm/`)
Hyprland-specific utilities: monitor hotplug handling, wallpaper selection via wofi, keyboard layout switching, screenshot capture (grim/slurp), clipboard management (cliphist). These are bound to keybindings in `dotfiles/hyprland/hyprland.conf`.

## Conventions

- All scripts use `#!/usr/bin/env bash` and typically `set -euxo pipefail` or `set -x`
- Primary language is Bash; Python used sparingly for specialized tools (Spotify, weather, backup)
- Hyprland is the primary WM; Sway configs exist as an alternative
- Target platform is Arch Linux with pacman; legacy multi-distro setup support remains in the archived OS framework
- Config files follow each app's native format (Lua for nvim, JSON for waybar/vscode, INI-like for most others)

## Known Issues

See `SHORTCOMINGS` for current bugs and TODO items (monitor switching, notification styling, clipboard tools, etc.).
