function run {
	if [ -n "$2" ]; then
		echo "$2"
	fi
	echo "Command: $1"
	eval "$1"
	echo
}

function ask {
	echo $1
	echo -n "Your choice: "
	read key
}

run "timedatectl set-ntp true" "Setting NTP"

run "fdisk -l"

ask "Run mkswap? Y - yes"
if [ ${key:-N} = 'Y' ]; then 
	ask "Partition number N (will become /dev/nvme0n1pN)"
	PART_NUM=$key
	ask "Size (in GB)"
	run "mkswap /dev/nvme0n1p$PART_NUM ${key}G"
fi

while [ ${key:-N} != 'Y' ]; do
	run "parted" "Partitioning disks"
	ask "Did you finished paritioning? If so, press Y"
done

echo "Installation finished successfully! "

echo "Running swapon"
run "fdisk -l"
ask "Partition number N (will become /dev/nvme0n1pN)"
run "swapon /dev/nvme0n1p$key"

ask "Root artition number N (will become /dev/nvme0n1pN)"
run "mount /dev/nvme0n1p${key} /mnt"

ask "Boot artition number N (will become /dev/nvme0n1pN)"
echo "Mountpoint: /mnt/boot"
run "mount /dev/nvme0n1p${key} /mnt/boot/"

run "pacstrap /mnt base linux linux-firmware"
run "genfstab -U /mnt >> /mnt/etc/fstab"

run "arch-chroot /mnt/"

