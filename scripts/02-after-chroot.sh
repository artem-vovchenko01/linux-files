#! /usr/bin/env bash
source 00-common.sh

banner "Continuing installation - after chroot"

exc "ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime"
exc "hwclock --systohc"

exc "nvim /etc/locale.gen"
exc "locale-gen"
exc "echo 'LANG=en_US.UTF-8' >> /etc/locale.conf"
exc "cat /etc/locale.conf"

exc "echo arch > /etc/hostname"
exc "cat /etc/hostname"
exc "echo '127.0.0.1	localhost' >> /etc/hosts"
exc "echo '::1		localhost' >> /etc/hosts"
exc "echo '127.0.1.1	arch.localdomain arch' >> /etc/hosts"

exc "passwd"
exc "pacman -S grub efibootmgr networkmanager dialog wpa_supplicant reflector sudo linux-headers avahi xdg-user-dirs xdg-utils inetutils dnsutils openssh flatpak ntfs-3g dosfstools os-prober mtools terminus-font acpi acpi_call"
exc_int "pacman -S tlp"
exc_int "pacman -S xf86-video-amdgpu"

exc "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
exc "grub-mkconfig -o /boot/grub/grub.cfg"

exc "systemctl enable NetworkManager"
exc_int "systemctl enable tlp"
exc "systemctl enable avahi-daemon"
exc "systemctl enable reflector.timer"
exc "systemctl enable acpid"

exc "useradd -m artem"
exc "passwd artem"
exc "echo 'artem ALL=(ALL) ALL' >> /etc/sudoers.d/artem"

msg_warn "Base installation complete! Now reboot and execute next script or do it now. If you want now, do su artem. But advise to reboot"

