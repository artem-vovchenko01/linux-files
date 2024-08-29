set -o pipefail
DIR=$(lsblk -o name,mountpoints,size,type,fstype,label -l | grep /mnt | wofi --dmenu | awk '{print $2}')
[[ $PIPESTATUS -ne 0 ]] && exit

kitty bash -c "set -x; sudo lsof /mnt/usb_kingston 2> /dev/null; sudo umount $DIR; echo Press Return to close ...; read"
