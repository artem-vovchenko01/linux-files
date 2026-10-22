# Integrations

## EPAM services

Teams, Outlook, calendar, SharePoint, Jira, Confluence, Azure DevOps, Power
Automate, and GitLab go through the scripts in
`~/obsidian/obsidian-work/.ai/epam/`. Routing is in its `README.md`. Writes
need my per-action approval.

## Telegram

Two routes. The `use-telegram` skill covers both, the replica, and the chat
ids:

- **My account**: the `tg` CLI in `~/cockpit-core/skills/use-telegram/`
  (a full user session). It exists only on my local machine, not on cloud
  setups.
- **Bot `@my_assistant_grok_bot`**: the Bot API token is in
  `~/cockpit-core/secrets/telegram-grok-bot-token` and
  `~/obsidian/obsidian-work/.ai/telegram/.grok_bot_token`. Syncthing syncs both,
  and git ignores both. The Grok Bot machines also keep it in their agent
  secrets. Never print it.

When I ask you to send me something or notify me on Telegram, use the bot
and send to my chat id `448468987`. A message from my own account does not
ping me. Where `cockpit-core` is absent, read the obsidian-work path.

    T=$(cat ~/cockpit-core/secrets/telegram-grok-bot-token)
    U="https://api.telegram.org/bot$T/sendMessage"
    curl -s "$U" -d chat_id=448468987 --data-urlencode text="..."

## Telegram channels for every agent

The bot `@my_assistant_grok_bot` is in my productivity and learning groups. They are my working inbox and notebooks. Any agent may use them when
a task needs them, not only Grok Bot:

- **AI productivity** (forum group):
  - `Tasks`: my personal backlog. Each item is one message, numbered
    `P<n> · <status> · <title>`.
  - `Work tasks`: the work backlog, numbered `W<n> · <status> · <title>`.
  - `Meeting summaries`, `Grok Bot Health` (weekday health status), `General`.
- **Productivity** (group): `Tasks` and `Work` are my
  quick-capture inboxes. One message is one task, and a done task is
  deleted.
- **AI assisted learning** (forum group): AI-assisted
  learning notes, one topic per subject, for example `General`, `Worth your
  time`, `My reading`, `Math`, `Physics`, `AI & future`, `IT`. A second
  group with the same name is an old basic group.
- **Learning** (group): topic notebooks, plus the knowledge chats `My
  reading`, `IT`, `History`, `Content processing`, and `Apeiron notes`. The
  7-day digest is
  `~/obsidian/obsidian-personal/.ai/telegram-replica/learning-digest-7d.md`.
- **Quick capture**: group `Daybook` for short diary notes, and Saved
  Messages on my own account.

Rules:

- Read first. The replica in `~/obsidian/obsidian-personal/Telegram.md`
  is a read-only copy of the knowledge chats. It does not mirror
  `AI assisted learning` yet, so read that group live.
- Add or delete a task only when I ask. Keep the `P` or `W` numbering when
  you add an item.
- Post into a channel only when the task calls for it or I ask.
- The corporate EPAM Grok Bot box has no personal chats. Skip these channels
  there.
- Chat names and topic names are enough. Use the ids in the `use-telegram`
  skill when a name is ambiguous.
