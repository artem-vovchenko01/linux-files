set -o pipefail
DISK=$(lsblk -o name,size,type,fstype,label,mountpoints -l | sed '/NAME/d; /SWAP/d; /luks/d; /lvm/d' | sort -k7 | wofi --dmenu | awk '{print $1}')
[[ $PIPESTATUS -ne 0 ]] && exit

DIR=$(echo $(ls /mnt) other | xargs -n1 | wofi --dmenu)
[[ $PIPESTATUS -ne 0 ]] && exit

case $DIR in
	"other")
		DIR=$(wofi --dmenu --prompt)
		[[ $? -ne 0 ]] && exit
		kitty sudo mkdir -p /mnt/$DIR
		;;
esac

kitty bash -c "set -x; sudo mount -o uid=1000,gid=1000 /dev/$DISK /mnt/$DIR; echo Press Return to close ...; read"
