lib log banner "Continuing installation - after chroot"

lib run "ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime"
lib run "hwclock --systohc"

lib run "sed -Ei '/# ?en_US\.UTF-8 UTF-8/s/#.*/en_US.UTF-8 UTF-8/' /etc/locale.gen"
lib run "locale-gen"
lib run "echo 'LANG=en_US.UTF-8' >> /etc/locale.conf"
lib run "cat /etc/locale.conf"

lib run "echo arch > /etc/hostname"
lib run "cat /etc/hostname"
lib run "echo '127.0.0.1	localhost' >> /etc/hosts"
lib run "echo '::1		localhost' >> /etc/hosts"
lib run "echo '127.0.1.1	arch.localdomain arch' >> /etc/hosts"

lib run "passwd"
lib run "sed -i '/#ParallelDownloads/s/#.*/ParallelDownloads = 10/' /etc/pacman.conf"
lib run "pacman -Sy reflector neovim"
lib run "root_mirror"
lib run "pacman -S grub efibootmgr networkmanager dialog wpa_supplicant sudo linux-headers avahi xdg-user-dirs xdg-utils inetutils dnsutils openssh flatpak ntfs-3g dosfstools os-prober mtools terminus-font acpi acpi_call"
lib run interactive "pacman -Sy tlp"
lib run interactive "pacman -S xf86-video-amdgpu"

lib run "echo GRUB_DISABLE_OS_PROBER=false | tee -a /etc/default/grub"
lib run "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
lib run "grub-mkconfig -o /boot/grub/grub.cfg"

lib run "systemctl enable NetworkManager"
lib run interactive "systemctl enable tlp"
lib run "systemctl enable avahi-daemon"
lib run "systemctl enable reflector.timer"
lib run "systemctl enable acpid"

lib run "useradd -m artem"
lib run "passwd artem"
lib run "echo 'artem ALL=(ALL) ALL' >> /etc/sudoers.d/artem"
lib run "mv /linux-files /home/artem/"
lib run "chown -R artem:artem /home/artem/linux-files"

lib log warn "Base installation complete! linux-files moved to /home/artem. Now reboot and execute next script or do it now. If you want now, do su artem. But advise to reboot"
lib log warn "exit"
lib log warn "umount -R /mnt"
lib log warn "reboot"

