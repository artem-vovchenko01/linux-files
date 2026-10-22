#!/usr/bin/env bash
# Local VM helper: vm.sh up|down|status|connect|shot|run ubuntu|windows
set -euo pipefail
cmd=${1:-status}; vm=${2:-}
CTL=~/logseq/logseq-work/.agents/skills/epam-vm-control/scripts/vmctl.py
case "$vm" in
  ubuntu) dir=~/vms/epam-vm; port=5901; run=$dir/run.sh ;;
  windows) dir=~/vms/windows; port=5902; run=$dir/run_vm.sh ;;
  "") [ "$cmd" = status ] || { echo "need ubuntu|windows"; exit 2; } ;;
  *) echo "unknown vm: $vm"; exit 2 ;;
esac
qmp() { # send one QMP command
  python3 - "$dir/qmp.sock" "$1" <<'PY'
import json,socket,sys
s=socket.socket(socket.AF_UNIX);s.connect(sys.argv[1]);f=s.makefile('rwb')
f.readline();f.write(b'{"execute":"qmp_capabilities"}\n');f.flush();f.readline()
f.write(json.dumps({"execute":sys.argv[2]}).encode()+b'\n');f.flush()
print(f.readline().decode().strip())
PY
}
st() {
  local a=off
  systemctl --user -q is-active "localvm@$1" && a=running
  printf '%-8s unit=%-8s vnc=' "$1" "$a"
  timeout 1 bash -c "</dev/tcp/127.0.0.1/$2" 2>/dev/null \
    && echo "127.0.0.1:$2 up" || echo down
}
case "$cmd" in
  run) exec "$run" ;;
  up)
    systemctl --user start "localvm@$vm"
    for _ in $(seq 1 60); do
      [ -S "$dir/qmp.sock" ] && break; sleep 0.5
    done
    VMCTL_DIR=$dir python3 "$CTL" status ;;
  down) systemctl --user stop "localvm@$vm" ;;
  powerdown) [ -S "$dir/qmp.sock" ] || exit 0
    qmp system_powerdown
    for _ in $(seq 1 80); do
      pgrep -f "qemu-system.*-name ${vm/windows/windows11}" >/dev/null || exit 0
      sleep 1
    done ;;
  reset) qmp system_reset ;;
  shot) VMCTL_DIR=$dir python3 "$CTL" shot ;;
  ctl) shift 2; VMCTL_DIR=$dir exec python3 "$CTL" "$@" ;;
  connect) exec remote-viewer "vnc://127.0.0.1:$port" ;;
  status)
    if [ -n "$vm" ]; then st "$vm" "$port"
    else st ubuntu 5901; st windows 5902; fi ;;
  *) echo "usage: vm.sh up|down|status|connect|shot|reset|ctl VM ..."
     exit 2 ;;
esac
