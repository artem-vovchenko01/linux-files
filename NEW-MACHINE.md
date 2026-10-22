# New machine

The order for a fresh install, on Omarchy or any other distro. An agent
runs the steps and asks Artem only where a step says so. Read
`AGENT_INSTRUCTIONS.md` and `ai/CLAUDE_GLOBAL_CONFIG.md` first.

## 1. Bootstrap (Artem, done before the agent starts)

    git clone https://github.com/artem-vovchenko01/linux-files ~/linux-files
    ~/linux-files/bootstrap.sh

This installs git, gpg and the Claude CLI and unpacks the restore kit
(`restore-kit-*.tar.gpg` on the Ventoy stick) into `~/DATA`:
`IT` (Syncthing identity, SSH creds), `work-resources`, `Private_data`.
The kit passphrase is in Bitwarden. Check that `~/DATA/IT/configs/syncthing/config.xml`
exists. Without it Syncthing starts with a new device ID, and every peer
must accept the new ID (`cockpit-core` skill `syncthing-workflow`).

## 2. setup.sh, first pass (Artem runs it in a terminal)

`setup.sh` asks y/N before each install and needs sudo, so Artem runs
`~/linux-files/setup.sh` himself. The first pass installs packages and
Syncthing, and starts Syncthing with the restored identity. The phone and
the Grok Bot boxes reconnect by themselves through global discovery.

## 3. Wait for the hubs to sync (agent)

The Syncthing GUI and REST API are on `127.0.0.1:8384`. The API key is in
`~/DATA/IT/configs/syncthing/config.xml`. Wait until these folders are at
100%: `cockpit-core`, `obsidian-personal`, `obsidian-work`,
`agentic-context`, `local-git`. The external HDD folders show an error
until the HDD is mounted. That error is expected.

## 4. setup.sh, second pass (Artem)

With the hubs present, the second pass links skills, agent settings and
agent memories, connects the rclone remotes `gdrive` (main Google account) and
`gdrive-ext` (ext account), and offers the `syncthing-workflow` timer.

## 5. Hub history (agent)

Syncthing brings the hub files without `.git`. Attach each hub to its
bare repo in `~/DATA/local-git`, and never clone over the synced files:
`~/DATA/local-git/README.md`, section "Re-establish git". The hubs are
`~/DATA/cockpit-core`, `~/obsidian/obsidian-personal` and
`~/obsidian/obsidian-work`. Then run `setup.sh` again so it adds the
`local` remotes.

## 6. Logins (Artem, the agent lists what is still missing)

- Agent CLIs: `claude`, `claude-alt`, `codex`, `codex-alt`, `grok`,
  `grok-alt`, `opencode`, `cursor-agent`.
- Bitwarden (`bw login`), browsers, Telegram Desktop, Tailscale.
- Work CLIs when needed: `az login`, `aws`, `databricks`.

## 7. Optional restores

- Google Drive `gdrive-ext:Laptop_archive_2026-10/`: pictures, Telegram
  files, downloads, and the encrypted laptop secrets archive.
- Google Drive `gdrive-ext:Syncthing_snapshot_2026-10-22/`: zips of the
  personal Syncthing folders, a fallback if the phone is lost.
