sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo rm -vf /var/log/wtmp /var/log/btmp
sudo rm -vf /var/log/*/*
sudo apt clean all
sudo apt autoclean
sudo fstrim -va
sudo systemctl restart systemd-journald.service
sudo rm -rf /var/log/journal/*

