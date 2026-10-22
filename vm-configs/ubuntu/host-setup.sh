#!/usr/bin/env bash
# One-time host setup for the Ubuntu VM. Run as root; safe to re-run.
# Installs the pcscd drop-in that leaves the YubiKey to the VM.
set -euo pipefail

here=$(dirname "$(readlink -f "$0")")
dropin=/etc/systemd/system/pcscd.service.d/ignore-yubikey.conf

install -D -m 644 "$here/pcscd-ignore-yubikey.conf" "$dropin"
systemctl daemon-reload
# No pcscd on the host (e.g. a fresh Arch) is fine: the drop-in waits for it.
systemctl try-restart pcscd.service || true
