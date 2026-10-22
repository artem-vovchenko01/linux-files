#!/usr/bin/env bash
set -euo pipefail

VMS="$HOME/vms/windows"
DISK="$VMS/windows.qcow2"
ISO="$VMS/Win11_25H2_EnglishInternational_x64_v2.iso"
NVRAM="$VMS/windows_OVMF_VARS.fd"
TPMDIR="$VMS/tpm"
TPMSOCK="$TPMDIR/swtpm.sock"
TPMPID="$TPMDIR/swtpm.pid"

RAM=${VM_RAM:-12G}
CPUS=$(( $(nproc) / 2 ))
DISK_SIZE=100G

# edk2 firmware: Fedora path, else Arch.
OVMF_CODE=/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd
OVMF_VARS=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd
if [ ! -f "$OVMF_CODE" ]; then
  OVMF_CODE=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd
  OVMF_VARS=/usr/share/edk2/x64/OVMF_VARS.4m.fd
fi

cleanup_tpm() {
  local comm
  local pid

  if [ -f "$TPMPID" ]; then
    pid=$(cat "$TPMPID")
    comm=$(ps -p "$pid" -o comm= 2>/dev/null || true)
    if [ "$comm" = swtpm ]; then
      kill "$pid" 2>/dev/null || true
    fi
  fi
  rm -f "$TPMSOCK" "$TPMPID"
}

mkdir -p "$VMS" "$TPMDIR"
[ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
[ -f "$NVRAM" ] || cp "$OVMF_VARS" "$NVRAM"

cleanup_tpm
trap cleanup_tpm EXIT

swtpm_args=(
  socket
  --tpm2
  --tpmstate dir="$TPMDIR"
  --ctrl type=unixio,path="$TPMSOCK"
  --pid file="$TPMPID"
  --daemon
)

swtpm "${swtpm_args[@]}"

for _ in {1..50}; do
  [ -S "$TPMSOCK" ] && break
  sleep 0.1
done

qemu_args=(
  -name windows11
  -enable-kvm
  -machine q35,smm=on,accel=kvm
  -cpu host
  -smp "$CPUS"
  -m "$RAM"
  -global driver=cfi.pflash01,property=secure,value=on
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE"
  -drive if=pflash,format=raw,unit=1,file="$NVRAM"
  -device ahci,id=sata
  -drive file="$DISK",if=none,id=disk0,format=qcow2,cache=writeback
  -device ide-hd,drive=disk0,bus=sata.0
  -boot order=dc,menu=on
  -display "${VM_DISPLAY:-gtk}"
  -vnc 127.0.0.1:2,share=force-shared
  -qmp unix:"$VMS/qmp.sock",server=on,wait=off
  -vga std
  -device qemu-xhci,id=xhci
  -device usb-tablet
  -device e1000e,netdev=n0
  -netdev user,id=n0,hostfwd=tcp:127.0.0.1:3389-:3389
  -audiodev pa,id=snd0
  -device ich9-intel-hda
  -device hda-output,audiodev=snd0
  -chardev socket,id=chrtpm,path="$TPMSOCK"
  -tpmdev emulator,id=tpm0,chardev=chrtpm
  -device tpm-tis,tpmdev=tpm0
)

if [ -f "$ISO" ]; then
  qemu_args+=(
    -drive file="$ISO",if=none,id=cdrom0,media=cdrom,readonly=on
    -device ide-cd,drive=cdrom0,bus=sata.1
  )
fi

qemu-system-x86_64 "${qemu_args[@]}"
