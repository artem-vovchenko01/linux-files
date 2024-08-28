HOST=182
if [ -n "$1" ]; then
	HOST=$1
fi

#if [ "$(ip route | grep default | wc -l)" -eq 2 ]; then
#	sudo ip route del default
#fi
sudo ip route del default
sudo ip route del default
sudo ip route add default via 192.168.0.$HOST
