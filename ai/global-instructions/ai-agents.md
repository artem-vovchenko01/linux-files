# AI agents in my setup

Many agents work on my files. Know which one you are and where you run
before you rely on a path, a hub, or a tool.

## Local machine

- **Host name**: usually `fedora` (tailnet name too). I may reinstall the
  OS or switch distro later, so check `hostname` and `/etc/os-release`
  instead of assuming Fedora.
- **CLI agents that may run here**: Claude Code (`claude`, `claude-alt`),
  Codex (`codex`, `codex-alt`), Grok CLI (`grok`, `grok-alt`), OpenCode
  (`opencode`), Cursor agent CLI (`cursor-agent` / `agent`), Muse CLI
  (`muse`), Google Antigravity (`agy`), and Gemini CLI (`gemini`).
- **Cursor GUI**: I may also run agents from the Cursor editor. They share
  the same repos and hubs.
- Several of these agents can work in one repo at the same time. Read
  before you write, check `git status`, and prefer appending.

## Grok Bot

Grok Bot is a chat assistant with its own cloud computer (a VM per
account). It has three accounts:

- **One corporate** (EPAM enterprise account). Its VM has only
  `~/obsidian/obsidian-work`. No `~/cockpit-core`, no `~/obsidian/obsidian-personal`,
  no personal data.
- **Two personal**. Their VMs may hold all hubs.

I may talk to Grok Bot from my phone, with or without a link to the local
machine. When the laptop is reachable, Grok Bot can hand terminal work to
the local CLIs (skill `grok-bot-delegator`). When it is not, the bot works
on its own VM only.

Account registry, boxes, and how a bot proves which account it is:
`~/obsidian/obsidian-work/.ai/grok-bot-communication/ACCOUNTS.md`.

Grok Bot does not load the global instructions on its own. Its hub folder
points to them through `GROK.md`. Its read order and extra rules are in
`grok-bot.md`.

## Retired assistants

Hermes and OpenClaw ran here before. They are unused now. Their notes and
skills stay as history. Do not start, configure, or route work to them
unless I ask.

## What this means for you

- Check that a hub or path exists before you use it. A missing personal hub
  on a Grok Bot VM is expected, not an error.
- Do not assume the local machine is on, reachable, or named `fedora`.
- Rules in this file apply to every agent above, whether it loads this file
  directly or through a hub's `AGENT_INSTRUCTIONS.md`.
