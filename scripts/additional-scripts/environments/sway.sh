lib log "Setting up sway"

# exc_int "paru -S ly"
lib pkg install sddm
lib pkg install sway
lib pkg install xdg-desktop-portal-wlr

lib run "sudo systemctl enable sddm"

# exc_int "mkdir ~/.config/sway"
# exc_int "cp /etc/sway/config ~/.config/sway/"

lib run "gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'"
lib run "gsettings set org.gnome.desktop.interface icon-theme 'breeze-dark'"

