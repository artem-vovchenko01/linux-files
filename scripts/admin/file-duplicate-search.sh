#!/usr/bin/env bash

# Temp directory
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# Information
notify-send "Choose directory to scan for duplicates"
notify-send "Exit when in proper directory"

# Pick directory to scan
kitty vifm --choose-dir $TMP_DIR/chosen_dir
DIR=$(cat $TMP_DIR/chosen_dir)

# Create script for processing each file
cat <<EOF > ./eval_files.sh
	echo -n \$(md5sum "\$1" | awk '{print \$1}') " "
	BYTES=\$(du -bs "\$1" | awk '{print \$1}')
	echo \$BYTES | numfmt --padding=10 | tr -d '\n'
  echo -n " "
	echo \$BYTES | numfmt --to=iec --padding=7 | tr -d '\n'
  echo -n " "
  echo "\$1"
EOF
chmod +x ./eval_files.sh
cat ./eval_files.sh

# Create script for scanning and interacting with user
cat <<EOF > ./run.sh
	find -H "$DIR" -type f -exec ./eval_files.sh {} \; | tee files.txt
	cat files.txt | sort -k2,2nr -k1,1 > sorted.txt
	echo ===================================
	echo SCANNING FINISHED
	echo ===================================
	echo State files are placed in: $TMP_DIR
	echo Press Return to show sorted files ...
	read
	cat sorted.txt
	read
	echo Press Return to exit ...
EOF
chmod +x ./run.sh
cat ./run.sh

# Scan
kitty ./run.sh
