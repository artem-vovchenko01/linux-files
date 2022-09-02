# /bin/bash

ps aux | grep "Discord" | cut -d' ' -f 3
ps aux | grep discord | sed -E "s/$(whoami)\ *//" | cut -d' ' -f 1 | head -n -2 | xargs kill  

