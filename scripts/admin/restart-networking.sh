sudo systemctl restart NetworkManager
nmcli g reload
nmcli c down Wired\ connection\ 1
nmcli c up Wired\ connection\ 1
