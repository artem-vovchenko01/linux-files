# menu: Laptop: enable the ssh server and open it in ufw
sudo apt install openssh-server
sudo systemctl enable --now ssh
sudo ufw allow OpenSSH
