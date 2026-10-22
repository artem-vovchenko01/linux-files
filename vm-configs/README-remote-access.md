# Remote access to the local VMs

The QEMU VMs on this Fedora host are reachable from other tailnet peers
(mainly `grok-bot-box`) through `tailscale serve`. Nothing is exposed to the
internet: serve is tailnet-only (Funnel is off).

## Port mappings

| Tailnet port | Local target       | What                                  |
| ------------ | ------------------ | ------------------------------------- |
| 5901         | `127.0.0.1:5901`   | Ubuntu `epam-vm` VNC (`ubuntu/run.sh`) |
| 5902         | `127.0.0.1:5902`   | Windows VNC (`windows/run_vm.sh`)     |
| 3389         | `127.0.0.1:3389`   | Windows RDP (QEMU `hostfwd` → guest `:3389`) |

Peers reach them at `<laptop tailnet name>:<port>` or `<laptop tailnet IP>:<port>`.

The mappings live in the system `tailscaled` state, so they survive reboots
and `tailscaled` restarts. Check them with `tailscale serve status`. Remove
one with `tailscale serve --tcp=<port> off`.

## Why tailscale serve

QEMU binds VNC to `127.0.0.1` only (`-vnc 127.0.0.1:N`), and RDP reaches the
host through the user-mode network `hostfwd`, also bound to `127.0.0.1`.
Neither listens on the LAN or on `tailscale0`. `tailscaled` accepts the
tailnet connection and proxies it to the loopback port.

```
grok-bot-box → tailnet → tailscaled (fedora :5901/:5902/:3389)
             → 127.0.0.1:<port> → QEMU (VNC server, or hostfwd → guest RDP)
```

## Box side

On `grok-bot-box`, use `~/bin/vm-view` to open the VNC consoles.

## Windows RDP

RDP needs two things:

1. Remote Desktop enabled inside Windows: Settings > System > Remote Desktop.
2. The `hostfwd=tcp:127.0.0.1:3389-:3389` forward in `windows/run_vm.sh`.
   QEMU reads it only at start, so a running VM picks up an edit to it only
   after a restart (`systemctl --user restart localvm@windows`).

Until both hold, the tailnet port 3389 accepts the connection and then drops
it.
