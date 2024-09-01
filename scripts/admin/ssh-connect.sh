HOSTS=$(cat ~/.ssh/config ~/custom-setup/shared/ssh-config | grep '^Host ' | awk '{print $2}')

CHOICE=$(echo "$HOSTS" | wofi --dmenu)
[[ $PIPESTATUS -ne 0 ]] && exit

kitty bash -c "ssh $CHOICE; echo 'Press Return to close the terminal'; read"
