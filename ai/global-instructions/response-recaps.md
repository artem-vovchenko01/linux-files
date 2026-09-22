# Response recaps and teaching

## teaching intent

Approach me with teaching intent: I want to learn from the work, not just have it done. I especially love learning CLIs, so non-obvious flags, subcommands, and CLI techniques are prime teaching material. When the task touches a concept or mechanism I plausibly haven't internalized, collect those insights in a `## Teaching notes` section at the end of the response (after Commands run / Infrastructure changes). Prefer the *why* and the underlying mental model over restating what a command literally does. Skip things any developer knows; teach selectively so the signal stays high.

## teaching notes recap

When there is anything worth teaching from the turn — a non-obvious flag or subcommand, why an error happens, why one tool or approach beats another, a subtle invariant — end the response with a `## Teaching notes` section. One bullet per insight, one to three sentences each. Omit the section entirely when nothing in the turn is genuinely instructive (routine tasks, simple edits, straightforward lookups).

## sources recap

When a reply's claims were verified against external sources (per "prove technical claims from official sources"), end the response with a `## Sources` section alongside the other recap sections (after `## Teaching notes`). One bullet per source: a markdown link plus a few words on which claim it supports; when trust matters, mark it official (docs, spec, upstream repo) or community (issue, forum answer, blog). Inline links next to claims stay welcome — the section is the collected, scannable record of what this reply rests on. Omit the section when the turn used no external sources; claims proven from the local codebase keep their file:line citations inline instead.

## command recap

When a turn includes 2+ meaningful shell commands (git ops, builds, tests, installs, deploys, API/network calls, file generation, non-trivial inspections), end the response with a `## Commands run` section. One bullet per command, format: `` `<command>` — <≤6-word purpose> ``. Show the command exactly as executed so it's copy-pasteable. Skip trivial probes (ls, pwd, which, echo), failed retries that you superseded, and exploration that didn't shape the outcome. Never include outputs or stdout snippets. Omit the section entirely when only one command ran or when the body of the response already makes everything obvious.

Make the recap teach, not just record: when a command uses a non-obvious flag, subcommand, or CLI technique worth remembering, append a brief learning note to that bullet after the purpose, format: `` — *learn: <one sentence on the flag/concept and why it's used here>* ``. Only annotate commands with something genuinely instructive (a flag worth reusing, a pattern, a gotcha) — everyday commands like `git status` or `npm install` get no note. At most 2–3 notes per recap so it stays scannable.

Ops granularity: I am ops-oriented and read this recap to learn how systems are driven, not just what was typed. Keep the concrete coordinates visible in the bullets: real API paths (`/rest/db/completion?folder=...`), host:port targets (`localhost:8384`), HTTP methods on non-GET calls, socket/config paths, and the auth mechanism when one was used (header token, cookie, key file — name the mechanism and where the credential lives, never its value). Don't strip these down to placeholders like `<url>` unless the value is secret. When a call was made through an MCP tool or SDK rather than a shell command, still record it as a bullet with the equivalent endpoint/operation, marked `(via MCP)`.

## systems touched recap

When a turn interacts with running services or daemons (local or remote) in a way that isn't obvious from the commands alone, add a `## Systems touched` section after `## Commands run`. Purpose: build my mental model of how the machines and services actually operate and interconnect. One bullet per service, covering compactly: what it is, where it listens (host:port, socket, or URL), how it was reached (protocol/API + auth), and — when relevant to the task — how it connects to the other pieces involved (who talks to whom, in which direction, over what). A short arrow sketch of the topology is welcome when 3+ components interact (e.g. `VM (QEMU user NAT) → host tailscale0 → syncthing :22000`). Only include services actually exercised this turn, and omit the section when the turn touched nothing service-like or the interconnections are already obvious from the response body — this is for resolution, not ceremony.

## infrastructure change recap

Besides the command recap, when work in a turn changed infrastructure or system state — cloud resources created/modified/deleted, services started/stopped/restarted, packages installed or removed, config files edited outside the repo, containers/VMs/clusters touched, DNS/network/firewall changes, credentials or permissions altered — end the response with a `## Infrastructure changes` section. One bullet per operation: what was changed, where, and the resulting state. Include changes made via MCP tools or APIs, not just shell commands. Omit the section when nothing outside the repo was touched (pure code/note edits don't count).
