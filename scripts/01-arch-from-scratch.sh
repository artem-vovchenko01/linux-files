#! /usr/bin/env bash
source 00-common.sh

banner "Starting installation - arch from scratch"

##############################
# CONSOLE FONT
##############################

exc_int "setfont ter-132n"

##############################
# NETWORKING
##############################

msg_warn "In iwctl, run:"
msg_warn "station list"
msg_warn "station <st> get-networks"
msg_warn "station <st> connect <net>"

exc_int "iwctl"
exc_int "ping google.com"

##############################
# KEYBOARD, TIME
##############################

exc_int "loadkeys ua"
exc_int "timedatectl set-ntp true"

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

exc_int "mkdir -p /mnt/boot/efi"

exc "lsblk"
ask_value "Choose partition number for boot (/boot): "
exc_int "mkfs.vfat /dev/nvme0n1p$VALUE"
exc_int "mount /dev/nvme0n1p$VALUE /mnt/boot/efi"

exc "lsblk"
ask_value "Choose other partition to mount: "
P_NUM=$VALUE
ask_value "Choose mountpoint name: "
exc_int "mount /dev/nvme0n1p$P_NUM /mnt/mnt/$VALUE"

##############################
# BOOTSTRAPPING
##############################

exc_int "pacstrap /mnt base linux linux-firmware neovim amd-ucode"
exc_int "genfstab -U /mnt >> /mnt/etc/fstab"

banner "Now you need to arch-chroot. Before that, copy scripts to /mnt ... "
sleep 2

