NEVER split a single shell command across multiple lines (no `\` continuations), so I can copy it cleanly.

Also, keep each shell line short enough to fit on one terminal row (~80 chars). Long lines wrap in my terminal and the wrap gets interpreted as a newline on paste, breaking the command. If a command would exceed ~80 chars, split it into multiple short *separate* commands using shell variables (e.g. `IMG=...` on one line, then `docker run ... $IMG` on the next) — not by line-continuing one command.

# command recap
When a turn includes 2+ meaningful shell commands (git ops, builds, tests, installs, deploys, API/network calls, file generation, non-trivial inspections), end the response with a `## Commands run` section. One bullet per command, format: `` `<command>` — <≤6-word purpose> ``. Show the command exactly as executed so it's copy-pasteable. Skip trivial probes (ls, pwd, which, echo), failed retries that you superseded, and exploration that didn't shape the outcome. Never include outputs or stdout snippets. Omit the section entirely when only one command ran or when the body of the response already makes everything obvious.
