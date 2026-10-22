#!/usr/bin/env bash
# Canonical launcher for the Ubuntu desktop VM.
# Lives in ~/linux-files/vm-configs/ubuntu; setup.sh symlinks it to
# ~/vms/epam-vm/run.sh, next to the local-only disk/iso/nvram payloads.
set -euo pipefail

# --- payload location (local-only, wiped by reinstall) ---------------------
VMS="$HOME/vms/epam-vm"
DISK="$VMS/ubuntu.qcow2"
ISO="$VMS/ubuntu-26.04.1-desktop-amd64.iso"
NVRAM="$VMS/ubuntu_OVMF_VARS.fd"

# --- remote control (agents) -----------------------------------------------
# QMP: screenshots and input for the epam-vm-control skill (vmctl.py).
# VNC: live view + control, loopback only, shared by all viewers at once.
# QEMU refuses VNC next to a GL display, so the VM uses 2D virtio-vga.
QMP_SOCK="$VMS/qmp.sock"
VNC_DISPLAY="127.0.0.1:1"         # port 5901

# --- resources -------------------------------------------------------------
RAM=10G
CPUS=$(( $(nproc) / 2 ))          # half of host threads
DISK_SIZE=64G

# --- UEFI firmware (edk2: Fedora path, else Arch) ---------------------------
OVMF_CODE=/usr/share/edk2/ovmf/OVMF_CODE.fd
OVMF_VARS=/usr/share/edk2/ovmf/OVMF_VARS.fd
if [ ! -f "$OVMF_CODE" ]; then
  OVMF_CODE=/usr/share/edk2/x64/OVMF_CODE.4m.fd
  OVMF_VARS=/usr/share/edk2/x64/OVMF_VARS.4m.fd
fi

# --- USB devices to hand through, as vendorid:productid --------------------
# Pass-by-ID survives replug/renumbering (bus.addr does not).
# `lsusb` to find more; append "0xVVVV:0xPPPP" entries here.
# The YubiKey also needs host pcscd to ignore it: `sudo ./host-setup.sh` once.
USB_PASSTHROUGH=(
  "0x1050:0x0407"   # Yubikey 4/5 OTP+U2F+CCID
)

# --- one-time setup --------------------------------------------------------
[ -f "$DISK" ]  || qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
[ -f "$NVRAM" ] || cp "$OVMF_VARS" "$NVRAM"

# Build the usb-host device args from the passthrough list.
usb_args=()
for dev in "${USB_PASSTHROUGH[@]}"; do
  usb_args+=(-device "usb-host,vendorid=${dev%%:*},productid=${dev##*:}")
done

cdrom_args=()
[ -f "$ISO" ] && cdrom_args=(-cdrom "$ISO")

exec qemu-system-x86_64 \
  -name ubuntu \
  -enable-kvm -machine q35,accel=kvm -cpu host \
  -smp "$CPUS" -m "$RAM" \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$NVRAM" \
  -drive file="$DISK",if=virtio,format=qcow2,cache=writeback \
  "${cdrom_args[@]}" \
  -boot order=dc,menu=on \
  -device virtio-vga -display "${VM_DISPLAY:-gtk}" \
  -vnc "$VNC_DISPLAY",share=force-shared \
  -qmp unix:"$QMP_SOCK",server=on,wait=off \
  -device qemu-xhci,id=xhci \
  "${usb_args[@]}" \
  -device virtio-net,netdev=n0 -netdev user,id=n0 \
  -audiodev pa,id=snd0 -device ich9-intel-hda \
  -device hda-output,audiodev=snd0 \
  -usb -device usb-tablet
