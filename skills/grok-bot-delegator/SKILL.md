---
name: grok-bot-delegator
description: Hand Grok Bot's work to the CLI coding agents (opencode, Claude Code, Codex, Grok CLI) instead of doing it inside the bot, so Grok Bot usage lasts. Covers which agent and model to pick, how to check each CLI is logged in and how much subscription usage is left, how to brief a delegated run, and how to collect the result. Use whenever a task can run in a terminal - code, files, repos, research, infra checks, EPAM tooling - or when Artem says "delegate this", "hand it to claude/codex/grok/opencode", "don't burn Grok Bot usage", "run it on the laptop".
---

# grok-bot-delegator

Grok Bot burns its usage fast, and every CLI agent on this machine runs on a
separate subscription that is otherwise idle. So Grok Bot coordinates and the
CLI agents work: read the task, pick an agent, write the brief, hand it over,
check what comes back, report to Artem.

**Grok Bot assistants use this skill often.** Work Bot, Cockpit Bot,
Personal Knowledge Bot, Remote Bot, Linux Files Bot, DevOps Server Bot, and any
other Grok Bot working in a hub that has this skill should default to
delegation whenever a task can finish in a terminal — that is how Artem wants
Grok Bot usage conserved. Also hand over large or difficult tasks that a CLI
agent can finish. Keeping heavy execution inside the bot when a CLI could take
it is the wrong default.

Delegate anything that a terminal can finish. Keep in Grok Bot only what needs
the bot itself: its browser, its app logins, its routines, and the judgment
about what Artem actually wants.

## Four copies of this skill

The same skill lives in four directories, as real files, not symlinks —
Syncthing replicates each hub on its own, and a link across hubs would break:

- `~/cockpit-core/skills/grok-bot-delegator/` — personal hub
- `~/logseq/logseq-work/.agents/skills/grok-bot-delegator/` — work hub
- `~/logseq/logseq-personal/.agents/skills/grok-bot-delegator/` — personal graph
- `~/linux-files/skills/grok-bot-delegator/` — linux-files / dotfiles repo

Edit one copy, then copy the whole folder over the other three. State in your
report which copies you changed.

## Where the work runs

**Prefer this machine.** Fedora laptop, tailnet name `fedora`. Grok Bot runs
here, so while the laptop is on the bot has direct access to it. All three
CLIs are installed and logged in, they reach Artem's repos, notes and EPAM
tooling, and the results land on the disk he actually uses.

**The cloud computer is the fallback.** Grok Bot's own always-on machine, the
one that keeps routines running when the laptop is off and when Artem messages
the bot from the phone. Use it only when the laptop is unavailable. Nothing
about it is assumed here — find out what it has before relying on it:

```
command -v claude codex grok        # which harnesses exist there
ls -d ~/.claude ~/.codex ~/.grok    # which ones have a home dir
```

Then run the login checks below. If a harness is missing or logged out, say so
to Artem instead of quietly doing the work in Grok Bot itself.

## Pick the agent

The models never change. What changes is the order they are tried in, and that
follows the weight of the task. First agent that works wins.

**Light task — `opencode` → `grok` → `codex` → `claude`.** Checking a ticket,
reading a file, a status lookup, a short summary, a grep, polling a build. Work
that fits in one command and one paragraph of answer. It goes to opencode first
because DeepSeek V4.1 Flash on the OpenCode Go subscription is cheap and quick
and plenty for simple jobs, then to Grok, whose remaining usage nobody can
measure anyway, and only after those to the two accounts whose quota is worth
saving for tasks that need it.

**Demanding task — `claude` → `codex` → `grok`.** Code changes, debugging,
multi-step research, anything where a wrong answer costs more than the run.

| Agent       | Model                        | Effort | CLI        |
| ----------- | ---------------------------- | ------ | ---------- |
| opencode    | `opencode-go/deepseek-flash` | high   | `opencode` |
| Claude Code | `claude-opus-5`              | medium | `claude`   |
| Codex       | `gpt-6-astra`                | medium | `codex`    |
| Grok CLI    | `grok-4.6`                   | medium | `grok`     |

`delegate.sh` takes the demanding ladder by default and the light one with
`-l`. It maps the generic effort onto each model: opencode's DeepSeek V4.1
Flash has only `low`, `high` and `max`, so the default `medium` becomes `high`
for it. When you cannot tell which a task is, ask whether being wrong would
cost Artem anything. If not, it is light.

When Artem names an agent or a model, use it — his choice outranks both
ladders. Effort levels are the same words everywhere: `low`, `medium`, `high`,
`xhigh`, `max`. Raise it only for genuinely hard work; medium is the default
for a reason.

Each CLI has a **second account** in its own home directory
(`~/.claude-alt`, `~/.codex-alt`, `~/.grok-alt`), reached through the wrapper
scripts `claude-alt`, `codex-alt`, `grok-alt`. When the first account is spent,
the same agent is still available on the second one — that is the `-A` flag of
`delegate.sh`. opencode has no second account, so `-A` leaves it on the primary.

## Before you hand anything over

```
./check-agents.sh            # every account: logged in? usage left?
./check-agents.sh claude     # one agent only
```

It reads credential files and the providers' status endpoints, so it costs no
model usage. What the numbers mean:

- **Claude** reports honestly: a 5-hour session percentage and a weekly
  percentage, straight from the OAuth usage endpoint. Above ~90% on either,
  drop to the next agent. Deeper handling, including swapping the whole login
  to Artem's other subscription, is the `claude-usage-guard` skill in
  `~/cockpit-core/skills/`.
- **Codex** has no usage command. The numbers come from the rate-limit
  snapshot in the newest session transcript, so they are as old as the last
  Codex run, and both accounts share one session store — the snapshot does not
  say which account produced it. Treat it as a hint.
- **Grok CLI** reports no quota at all. Its own docs call a rate-limit summary
  "a number it cannot source honestly"
  (`~/.grok/docs/user-guide/25-status-line.md`). You learn Grok's remaining
  usage only by running it.
- **opencode** reports no quota either. It bills the OpenCode Go subscription
  through the `opencode-go` entry in `~/.local/share/opencode/auth.json`;
  `check-agents.sh` only confirms that login is present.

Login checks on their own, when you want them without the usage calls:
`claude auth status` (JSON, read `loggedIn`), `codex login status`,
`grok models` (prints the account and the default model), `opencode auth list`
(lists the configured providers).

## Hand the task over

```
./delegate.sh "summarise what changed in this repo last week"
./delegate.sh -l "what is the status of EPMPMVISEX-1201" -d ~/logseq/logseq-work
./delegate.sh -f brief.md -d ~/EPAM/migvisor_explainer
./delegate.sh -a codex -m gpt-6-astra -e high -t 3600 -f brief.md
./delegate.sh -A -a claude -f brief.md        # second Claude account
./delegate.sh -n -f brief.md                  # dry run, prints the plan
```

The script walks the ladder for that weight class, skips agents that are missing or logged out, runs
the first usable one, and falls through to the next if that run fails. Its last
line always names the agent, model, account, session id and exit code behind
the answer — quote that line when you report back.

**Start the run in the right directory** (`-d`). The delegate inherits the
instructions and skills of the hub it starts in:

- `~/logseq/logseq-work` — EPAM and MigVisor work: Teams, Outlook, Jira,
  Confluence, Azure DevOps, the `.ai/epam/` scripts.
- `~/cockpit-core` — personal ops: Telegram, documents, the machine, Hetzner.
- a repo path — plain code work.

**Write the brief cold.** The delegate knows nothing about the Grok Bot
conversation. Give it: the goal, the repo or directory, the exact commands or
files if you already know them, what "done" looks like, what it must not touch,
and whether it may write or only read. `delegate.sh` already tells it that
nobody can answer questions mid-run.

**Long jobs go to the background**, so Grok Bot is not sitting in a blocked
terminal:

```
nohup ./delegate.sh -f brief.md -d ~/EPAM/repo > ~/delegated-repo.log 2>&1 &
```

Then poll the log file. Default timeout per attempt is 30 minutes; raise it
with `-t`.

### Running a CLI by hand

When `delegate.sh` is not there — the cloud computer, another machine — these
are the same invocations, verified on 2026-09-10:

```
cd <dir> && opencode run -m opencode-go/deepseek-flash --variant high --auto \
  --format json "<task>"
```
One JSON event per line: the answer is joined from the `text` events, the
session id is `.sessionID` on every event. `--auto` approves the safe actions,
so scope the run with the directory.

```
claude -p "<task>" --model claude-opus-5 --effort medium \
  --output-format json --dangerously-skip-permissions
```
Answer in `.result`, session in `.session_id`, failure flag in `.is_error`.

```
codex exec -m gpt-6-astra -c model_reasoning_effort="medium" \
  --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check \
  -C <dir> -o answer.txt "<task>"
```
Answer in `answer.txt`. Codex refuses to start outside a git repo without
`--skip-git-repo-check`. A `shell_snapshot` error line on startup is noise.

```
grok -p "<task>" --model grok-4.6 --reasoning-effort medium --cwd <dir> \
  --permission-mode bypassPermissions --output-format json
```
Answer in `.text`, session in `.sessionId`.

Each one runs unattended with approvals bypassed. That is deliberate — an
agent that stops to ask permission never finishes when nobody is watching — so
scope the run with the working directory and say in the brief what is off
limits.

## Collect the result

1. Read the answer before you believe it. A confident report is a claim; if
   something depends on it, check the file, the diff, or the command output.
2. Follow up in the same session instead of starting over:
   `claude --resume <id> -p "..."`, `codex exec resume <id> "..."`,
   `grok -p "..." --resume <id>`.
3. Failures are cheap to retry once on the next agent in the ladder. A second
   failure with the same message is a real problem — bring it to Artem with
   the message, not a summary of it.
4. Tell Artem what ran where: agent, model, account, and what changed on disk.

## Rules

- **Delegation moves execution, never judgment.** Deciding what Artem wants,
  what is worth doing, and what to tell him stays in Grok Bot.
- **Approvals do not transfer.** A delegate must not send Teams or Outlook
  messages, push commits, open or complete PRs, upload to SharePoint, or
  change infrastructure without Artem's explicit go for that action. Put the
  limit in the brief; reads are always fine.
- **No secrets in a brief.** Point at the file or the credential name, never
  the value.
- **Say which account paid.** Every report names the agent, model and account
  — Artem juggles these subscriptions and needs to know which one moved.
- **Do not delegate what needs Grok Bot itself**: its browser sessions, its app
  logins, its routines, or anything already half-done inside the bot.
