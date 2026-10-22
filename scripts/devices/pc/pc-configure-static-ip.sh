# menu: PC: static IP on the wired connection
nmcli c modify Wired\ connection\ 1 ipv4.addresses 192.168.0.84/24
nmcli c modify Wired\ connection\ 1 ipv4.gateway 192.168.0.1
nmcli c modify Wired\ connection\ 1 ipv4.dns 192.168.0.1
nmcli c modify Wired\ connection\ 1 ipv4.method manual 
