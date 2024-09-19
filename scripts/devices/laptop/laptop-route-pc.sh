sudo sysctl -w  net.ipv4.ip_forward=1

sudo iptables -t nat -A POSTROUTING -d 0/0 -s 192.168.0/24 -j MASQUERADE

sudo iptables -A FORWARD -s 192.168.0.0/24 -d 0/0 -j ACCEPT

sudo iptables -A FORWARD -s 0/0 -d 192.168.0.0/24 -j ACCEPT
