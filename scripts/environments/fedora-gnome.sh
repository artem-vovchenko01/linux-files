exc "~/.local/bin/scripts/gnome/gnome_shortcut_script.sh"
exc "sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
exc "sudo dnf autoremove"

# sudo dnf -y remove chrome-gnome-shell quota* nfs-utils teamd tcpdump adcli lvm2 qemu-guest-agent hyperv* gnome-classic* baobab *zhuyin* *pinyin* *evince* *yelp* fedora-bookmarks fedora-chromium-config gnome-tour gnome-themes-extra gnome-shell-extension-background-logo gnome-screenshot gnome-remote-desktop gnome-font-viewer gnome-calculator open-vm* *speech* sos totem gnome-characters firefox eog openssh-server dmidecode xorg-x11-drv-vmware xorg-x11-drv-amdgpu yajl words ibus-hangui vino openh264 twolame-libs realmd rsync net-snmp-libs net-tools traceroute mtr geolite2* gnome-boxes gnome-disk-utility gedit gnome-calendar cheese gnome-contacts rythmbox gnome-screenshot gnome-maps gnome-weather gnome-logs ibus-typing-booster *m17n* gnome-clocks gnome-color-manager mlocate cyrus-sasl-plain cyrus-sasl-gssapi sssd* gnome-user* dos2unix kpartx rng-tools ppp* ntfs* xfs* tracker* thermald *perl* gnome-shell-extension-apps-menu gnome-shell-extension-horizontal-workspaces gnome-shell-extension-launch-new-instance gnome-shell-extension-places-menu gnome-shell-extension-window-list file-roller* bluez* *cups* sane* simple-scan *hangul* NetworkManager-config-connectivity-fedora

# leave
# baobab evince gnome-screenshot gnome-maps gnome-weather gnome-logs gnome-clocks kpartx ppp* ntfs* xfs* gnome-shell-extension-background-logo gnome-remote-desktop gnome-font-viewer gnome-calculator totem gnome-characters eog words mtr gnome-boxes gnome-disk-utility gnome-calendar gnome-contacts thermald gedit cheese
ask "TAKE EXTREME CARE!!! Remove some unneeded gnome packages?" Y && {
for pkg in chrome-gnome-shell 'quota*' nfs-utils teamd tcpdump adcli lvm2 qemu-guest-agent 'hyperv*' 'gnome-classic*' '*zhuyin*' '*pinyin*' '*yelp*' fedora-bookmarks fedora-chromium-config gnome-tour gnome-themes-extra  'open-vm*' '*speech*' sos openssh-server xorg-x11-drv-vmware yajl realmd net-snmp-libs '*m17n*' 'sssd*' 'gnome-user*' 'tracker*' '*perl*' 'bluez*' '*cups*' 'sane*' simple-scan '*hangul*'; do
  msg_info "Removing $pkg"
  exc 'sudo dnf remove "$pkg"'
done
}

