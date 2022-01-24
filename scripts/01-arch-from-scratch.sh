#! /usr/bin/env bash
source 00-common.sh

banner "Starting installation - arch from scratch"

##############################
# CONSOLE FONT
##############################

exc "setfont ter-132n"

##############################
# NETWORKING
##############################

exc "ping google.com -c 3" || {
  msg_warn "In iwctl, run:"
  msg_warn "station list"
  msg_warn "station <st> get-networks"
  msg_warn "station <st> connect <net>"

  exc "iwctl"
  exc "ping google.com"
}

##############################
# KEYBOARD, TIME
##############################

exc "loadkeys ua"
exc "timedatectl set-ntp true"

##############################
# PARTITIONING
##############################

exc "lsblk"
ask_value "Choose partition number for swap: "
exc_int "mkswap /dev/nvme0n1p$VALUE"
exc_int "swapon /dev/nvme0n1p$VALUE"

exc "lsblk"
ask_value "Choose partition number for root (/): "
exc_int "mkfs.ext4 /dev/nvme0n1p$VALUE"
exc_int "mount /dev/nvme0n1p$VALUE /mnt"

exc "mkdir -p /mnt/boot/efi"

exc "lsblk"
ask_value "Choose partition number for boot (/boot): "
exc_int "mkfs.vfat /dev/nvme0n1p$VALUE"
exc_int "mount /dev/nvme0n1p$VALUE /mnt/boot/efi"

while true; do
  exc "lsblk"
  ask_value "Choose other partition to mount: "
  P_NUM=$VALUE
  ask_value "Choose mountpoint name: "
  exc "mkdir -p /mnt/mnt/$VALUE"
  exc_int "mount /dev/nvme0n1p$P_NUM /mnt/mnt/$VALUE"
  ask "Mount another partition?"
  [[ $? -eq 0 ]] || break
done

##############################
# BOOTSTRAPPING
##############################

exc "pacman -S reflector"
exc "reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
exc "sed -i '/#ParallelDownloads/s/#.*/ParallelDownloads = 10/' /etc/pacman.conf

exc "pacstrap /mnt base linux linux-firmware neovim amd-ucode"
exc "genfstab -U /mnt >> /mnt/etc/fstab"

banner "Now you need to arch-chroot. Before that, copy scripts to /mnt ... "
sleep 2
