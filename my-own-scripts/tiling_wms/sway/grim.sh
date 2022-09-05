#! /bin/sh

[ ! -e ~/Resources/Screenshots ] && mkdir -p ~/Resources/Screenshots

screenshot_path=~/Resources/Screenshots/Screenshot_$(date | sed 's/[^[:alnum:]]\+/_/g').jpg

if [ "$1" = "region" ]; then
    grim -t jpeg -q 85 -g "$(slurp -d)" - | tee $screenshot_path | wl-copy
    notify-send -i $screenshot_path "Region scrennshot taken"
else
    grim -t jpeg -q 85 - | tee $screenshot_path | wl-copy
    notify-send -i $screenshot_path "Fullscreen scrennshot taken"
fi

