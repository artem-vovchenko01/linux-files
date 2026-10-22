# menu: Restart waybar
killall -SIGUSR2 waybar
pkill waybar 
waybar & disown
