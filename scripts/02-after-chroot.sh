#! /usr/bin/env bash
source 00-common.sh

banner "Continuing installation - after chroot"

exc_int "ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime"
exc_int "hwclock --systohc"

exc_int "nvim /etc/locale.gen"
exc_int "locale-gen"
exc_int "echo 'LANG=en_US.UTF-8' >> /etc/locale.conf"
exc_int "cat /etc/locale.conf"

exc_int "echo arch > /etc/hostname"
exc_int "cat /etc/hostname"
exc_int "echo '127.0.0.1	localhost' >> /etc/hosts"
exc_int "echo '::1		localhost' >> /etc/hosts"
exc_int "echo '127.0.1.1	arch.localdomain arch' >> /etc/hosts"

exc_int "passwd"
exc_int "pacman -S grub efibootmgr networkmanager dialog wpa_supplicant reflector linux-headers avahi xdg-user-dirs xdg-utils inetutils dnsutils openssh tlp flatpak ntfs-3g dosfstools os-prober mtools terminus-font acpi acpi_call"
exc_int "pacman -S xf86-video-amdgpu"

exc_int "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
exc_int "grub-mkconfig -o /boot/grub/grub.cfg"

exc_int "systemctl enable NetworkManager"
exc_int "systemctl enable tlp"
exc_int "systemctl enable avahi-daemon"
exc_int "systemctl enable reflector.timer"
exc_int "systemctl enable acpid"

exc_int "useradd -m artem"
exc_int "passwd artem"
exc_int "echo 'artem ALL=(ALL) ALL' >> /etc/sudoers.d/artem"

msg_warn "Base installation complete! Now reboot and execute next script or do it now. If you want now, do su artem. But advise to reboot"

