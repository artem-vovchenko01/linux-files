#!/usr/bin/env bash
set -o pipefail

SCRIPTS=~/linux-files/scripts
VMS_PATH=~/EPAM/EPMA-DPAF/resources/creds/vms

# File or dir
TMP_DIR=$(mktemp -d)
CHOICE=$(echo file directory | xargs -n1 | wofi --dmenu)
[[ $PIPESTATUS -ne 0 ]] && exit
if [[ "$CHOICE" == "directory" ]]; then
  kitty bash -c "lf -print-last-dir > $TMP_DIR/chosen_dir"
  OBJ="$(cat $TMP_DIR/chosen_dir)"
else
  kitty bash -c "lf -print-selection > $TMP_DIR/chosen_file"
  OBJ="$(cat $TMP_DIR/chosen_file)"
fi

VMS=$(ls $VMS_PATH)
CHOICE=$(echo "$VMS" | wofi --dmenu)
[[ $PIPESTATUS -ne 0 ]] && exit

set -x
cd $VMS_PATH/$CHOICE && \
  kitty scp -ri $(ls *.pem) "$OBJ" $(cat ./user)@$(cat ./ip):/home/$(cat ./user)/
