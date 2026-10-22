# New machine

The order for a fresh install, on Omarchy or any other distro. An agent
runs the steps and asks Artem only where a step says so. Read
`AGENT_INSTRUCTIONS.md` and `ai/CLAUDE_GLOBAL_CONFIG.md` first.

## 1. Bootstrap (Artem, done before the agent starts)

    git clone https://github.com/artem-vovchenko01/linux-files ~/linux-files
    ~/linux-files/bootstrap.sh

This installs git, gpg and the Claude CLI.

## 2. setup.sh, first pass (Artem runs it in a terminal)

`setup.sh` asks y/N before each install and needs sudo, so Artem runs
`~/linux-files/setup.sh` himself. It asks where the restore kit is:

- `s`: the Ventoy stick, `restore-kit-*.tar.gpg`. It holds `IT` (Syncthing
  identity), `work-resources` and `Secrets` (SSH keys, Telegram account,
  private notes; map in `~/DATA/Secrets/README.md`).
- `d`: Google Drive. setup.sh opens the folder in the browser and waits
  while Artem signs in with the ext Google account and downloads
  `restore-kit-IT-*.tar.gpg` to `~/Downloads`. It holds `IT` only;
  `Secrets` and `work-resources` then come from the phone.
- `n`: a new device ID. Every peer must accept it (`cockpit-core` skill
  `syncthing-workflow`).

gpg asks for the kit passphrase from Bitwarden. Then setup.sh creates every
Syncthing folder under `~` with its saved `.stignore`
(`scripts/syncthing/st-folders.py restore`) and starts Syncthing with the
restored identity. The phone and the Grok Bot boxes reconnect by
themselves through global discovery.

## 3. Wait for the hubs to sync (agent)

The Syncthing GUI and REST API are on `127.0.0.1:8384`. The API key is in
`~/DATA/IT/configs/syncthing/config.xml`. Wait until these folders are at
100%: `cockpit-core`, `obsidian-personal`, `obsidian-work`,
`agentic-context`, `local-git`. The external HDD folders are paused until the HDD
is plugged in.

## 4. setup.sh, second pass (Artem)

With the hubs present, the second pass links skills, agent settings and
agent memories, connects the rclone remotes `gdrive` (main Google account) and
`gdrive-ext` (ext account), restores browser bookmarks (`scripts/browser/bookmarks.py`; start Firefox
once before, so it has a profile), and offers the `syncthing-workflow` timer.

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
