#!/usr/bin/env bash
# Free the YubiKey for the EPAM VM: stop the host smart-card daemon (pcscd),
# then re-attach the key to the running VM. Safe to re-run.
#
# While pcscd holds the key's smart-card interface, QEMU cannot configure the
# key. The guest then logs "can't set config #1, error -32" and has no FIDO
# device. pcscd starts again after a reboot, so re-run this before using the key.
#
# Usage:
#   fix-yubikey-vm-passthrough.sh                # stop pcscd, re-attach the key
#   fix-yubikey-vm-passthrough.sh --no-reattach  # only stop pcscd
#   fix-yubikey-vm-passthrough.sh --undo         # start pcscd again
#
# sudo asks for the password in the terminal.
set -euo pipefail

SOCK="$HOME/vms/epam-vm/qmp.sock"
UNDO=0
REATTACH=1

for arg in "$@"; do
  case "$arg" in
    --undo) UNDO=1 ;;
    --no-reattach) REATTACH=0 ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [ "$UNDO" = 1 ]; then
  sudo systemctl start pcscd.socket
  echo "pcscd.socket started"
  exit 0
fi

# is-active succeeds when any listed unit is active. Skip sudo when both are down.
if systemctl is-active --quiet pcscd.socket pcscd.service; then
  sudo systemctl stop pcscd.socket pcscd.service
fi
echo "pcscd: $(systemctl is-active pcscd.service || true)"

[ "$REATTACH" = 1 ] || exit 0

if [ ! -S "$SOCK" ]; then
  echo "EPAM VM is not running: the key attaches when it starts"
  exit 0
fi

# Detach the usb-host device that carries the YubiKey (vendor 0x1050), wait for
# the guest to see the unplug, then add it back on the guest's xHCI bus.
python3 - "$SOCK" <<'PY'
import json, socket, sys, time

s = socket.socket(socket.AF_UNIX)
s.connect(sys.argv[1])
f = s.makefile("rwb")
f.readline()


def call(name, **args):
    msg = {"execute": name}
    if args:
        msg["arguments"] = args
    f.write(json.dumps(msg).encode() + b"\n")
    f.flush()
    while True:
        reply = json.loads(f.readline())
        if "event" in reply:
            continue
        if "error" in reply:
            sys.exit(f"{name}: {reply['error']['desc']}")
        return reply["return"]


call("qmp_capabilities")
for root in ("/machine/peripheral", "/machine/peripheral-anon"):
    for child in call("qom-list", path=root):
        if child["type"] != "child<usb-host>":
            continue
        path = f"{root}/{child['name']}"
        if call("qom-get", path=path, property="vendorid") == 0x1050:
            call("device_del", id=path)
            time.sleep(4)

call("device_add", driver="usb-host", vendorid=0x1050, productid=0x0407,
     bus="xhci.0", id="yubikey")
print("YubiKey re-attached to the VM")
PY
