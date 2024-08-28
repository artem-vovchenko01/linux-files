lib log banner "Starting installation - arch from scratch"

##############################
# CONSOLE FONT
##############################

lib run "setfont ter-132n"

##############################
# UEFI TEST
##############################

lib run interactive "efivar-tester"

##############################
# NETWORKING
##############################

lib snippet ping || {
  lib log warn "In iwctl, run:"
  lib log warn "station list"
  lib log warn "station <st> get-networks"
  lib log warn "station <st> connect <net>"

  lib run "iwctl"
  lib snippet ping
}

##############################
# KEYBOARD, TIME
##############################

lib run "loadkeys ua"
lib run "timedatectl set-ntp true"

##############################
# PARTITIONING
##############################

lib run "lsblk"
lib input value "Choose partition number for swap: "
lib run interactive "mkswap /dev/nvme0n1p$VALUE"
lib run interactive "swapon /dev/nvme0n1p$VALUE"

lib run "lsblk"
lib input value "Choose partition number for root (/): "
lib run interactive "mkfs.ext4 /dev/nvme0n1p$VALUE"
lib run interactive "mount /dev/nvme0n1p$VALUE /mnt"

lib run "mkdir -p /mnt/boot/efi"

lib run "lsblk"
lib input value "Choose partition number for boot (/boot): "
lib run interactive "mkfs.vfat /dev/nvme0n1p$VALUE"
lib run interactive "mount /dev/nvme0n1p$VALUE /mnt/boot/efi"

while true; do
  lib run "lsblk"
  lib input value "Choose other partition to mount: "
  P_NUM=$VALUE
  lib input value "Choose mountpoint name: "
  lib run "mkdir -p /mnt/mnt/$VALUE"
  lib run interactive "mount /dev/nvme0n1p$P_NUM /mnt/mnt/$VALUE"
  lib input "Mount another partition?"
  [[ $? -eq 0 ]] || break
done

##############################
# BOOTSTRAPPING
##############################

lib run "pacman -S reflector"
lib run "root_mirror"
lib run "sed -i '/#ParallelDownloads/s/#.*/ParallelDownloads = 10/' /etc/pacman.conf"

lib run "pacstrap /mnt base linux linux-firmware neovim amd-ucode"
lib run "genfstab -U /mnt >> /mnt/etc/fstab"

lib run "mv ../../linux-files /mnt/"

lib log banner "Do 'cd', then arch-chroot to /mnt"
sleep 2

