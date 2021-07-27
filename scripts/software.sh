function ask {
	echo $1
	echo -n "Your choice: "
	read key 
}

key=Y

# pacman-mirrors -f
sudo pacman -Sy

soft=""

echo "Comment lines which you don't need ..."
sleep 2
vim software_list.txt
#for prog in $(cat software_list_temp.txt); do
#	ask "Install ${prog}?"
#	if [ ! $key = 'N' ]; then 
#	soft="${soft} ${prog}"
#		echo "Progs: ${soft}"
#	fi
#done

if ! pacman -Q | grep -q paru; then
	echo "Installing paru ..."
	git clone https://aur.archlinux.org/paru.git
	cd paru
	makepkg -si
	cd ..
	rm -rf paru
fi
paru -S $(cat software_list.txt | grep -v '#')

