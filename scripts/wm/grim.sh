#! /bin/sh
set -eo pipefail

PICTURES=~/Pictures

[ ! -e $PICTURES/Screenshots ] && mkdir -p $PICTURES/Screenshots

SCREENSHOT_PATH=$PICTURES/Screenshots/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png

if [ "$1" = "region" ]; then
    grim -t png -g "$(slurp -d)" - | tee $SCREENSHOT_PATH | wl-copy
    notify-send -i $SCREENSHOT_PATH "Region scrennshot taken"
else
    grim -t png - | tee $SCREENSHOT_PATH | wl-copy
    notify-send -i $SCREENSHOT_PATH "Fullscreen scrennshot taken"
fi

