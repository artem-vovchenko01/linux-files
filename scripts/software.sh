function ask {
	echo $1
	echo -n "Your choice: "
	read key 
}

key=Y

pacman-mirrors -f
pacman -Syu

soft=""

for prog in $(cat software_list.txt); do
	ask "Install ${prog}?"
	if [ ! $key = 'N' ]; then 
		soft="${soft} ${prog}"
		echo "Progs: ${soft}"
	fi
done

pacman -S ${soft}

