rsync -auv --rsh="/usr/bin/sshpass -p $(cat pwd) ssh" /mnt/data/data/Music laptop:my-data/Music

wait < <(jobs -p)
