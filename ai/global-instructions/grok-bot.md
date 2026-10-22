# Grok Bot

Grok Bot is a chat assistant with its own cloud computer. It works in one
hub folder on that computer. It does not load the global instructions by
itself, so it must read them on purpose. A local CLI agent starts in the
hub and loads `~/.claude/CLAUDE.md` for you. Grok Bot starts in the folder
and sees only what the folder says.

## Read order at the start of a session

1. `~/linux-files/ai/CLAUDE_GLOBAL_CONFIG.md`, then the topic files it
   names under `~/linux-files/ai/global-instructions/` when the topic
   applies.
2. `AGENT_INSTRUCTIONS.md` in the hub you work in.
3. This file.

If `~/linux-files` is missing on the box, look for a synced copy. If there
is none, say so, read the hub instructions, and ask Artem.

## Pointer file in your folder

Each hub root has a `GROK.md` file. In all three hubs it is a symlink to
`AGENT_INSTRUCTIONS.md`, and that file names the global instructions.

If your folder has no `.md` file that points to the global instructions:

- Create `GROK.md` in the folder root as a plain file with the lines below.
- Do not overwrite an existing `GROK.md` or its symlink.

```
- Read first: `~/linux-files/ai/CLAUDE_GLOBAL_CONFIG.md`, then the topic files it names.
- Then read `AGENT_INSTRUCTIONS.md` in this folder.
- Grok Bot rules: `~/linux-files/ai/global-instructions/grok-bot.md`.
- Telegram channels and tasks: `~/linux-files/ai/global-instructions/integrations.md`.
```

## Things Grok Bot often misses

- **Telegram holds the task backlogs.** Numbered items (`P<n>` personal,
  `W<n>` work) sit in the `AI productivity` group, topics `Tasks` and `Work
  tasks`. Quick-capture tasks sit in the `Productivity` group, topics `Tasks`
  and `Work`. Read them to see what is open. Add or delete an item only when
  Artem asks.
- **Telegram holds the learning notes.** They sit in the `AI assisted
  learning` group, one topic per subject. The `Learning` group and the
  knowledge chats hold older notes. Search the Telegram replica in
  `~/obsidian/obsidian-personal/Telegram.md` first. It does not mirror
  `AI assisted learning` yet, so read that group live.
- **The bot is in several groups.** `@my_assistant_grok_bot` posts and reads
  in them. The full list and the rules are in `integrations.md`.
- **Other agents use these channels too.** This is not a Grok-only rule.
- **Terminal work goes to a CLI agent.** Hand terminal-shaped and large jobs
  to Claude Code, Codex, or Grok CLI through the `grok-bot-delegator` skill.
- **Writes outside Telegram need approval.** That covers EPAM Teams, mail,
  SharePoint, flows, and GitLab. Reads are always fine.
- **Know your box.** The corporate EPAM box has only the work hub. It has no
  personal chats and no personal hub, so do not use the personal Telegram
  channels there.
- **No Microsoft token on a box (2026-10-15).** Never copy Fedora's Graph
  token or `~/.azure` to a box, even when asked to "work here all day": every
  box refresh leaves through Cloudflare, the pattern EPAM security flagged on
  2026-10-09. Run the usual `logseq-work/.ai/epam` scripts; on a box they
  ask Fedora through `relay.sh` (reads only). Exit 5 means Fedora is asleep
  or off. Detail: `logseq-work/.agents/skills/epam/references/logins.md`.
