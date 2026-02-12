# pkill -f wl-clip-persist
SCRIPTS=~/linux-files/scripts

pkill -f wl-paste

$SCRIPTS/tool/my_nohup wl-paste --type text --watch cliphist store
$SCRIPTS/tool/my_nohup wl-paste --type image --watch cliphist store

# for clipboard primary
$SCRIPTS/tool/my_nohup wl-paste -p --type text --watch cliphist store
$SCRIPTS/tool/my_nohup wl-paste -p --type image --watch cliphist store

# wl-clip-persist --clipboard regular 
# Copy link, copy in Teams doesn't work proper with persist, even just on regular clipboard. And in Logseq
# possibility: just exclude non-working apps from persistence
# wl-clip-persist --clipboard both 
# https://github.com/Linus789/wl-clip-persist
