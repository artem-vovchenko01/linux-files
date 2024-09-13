#!/usr/bin/env bash
SCRIPTS=~/linux-files/scripts
VMS_PATH=~/EPAM/EPMA-DPAF/resources/creds/vms

set -o pipefail
DPAF_VMS=$(ls $VMS_PATH)
CHOICE=$(echo "$DPAF_VMS" | wofi --dmenu)
[[ $PIPESTATUS -ne 0 ]] && exit

cd $VMS_PATH/$CHOICE
kitty ./connect.sh
