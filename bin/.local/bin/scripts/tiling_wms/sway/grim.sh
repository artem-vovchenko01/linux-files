[[ ! -e ~/Pictures/Screenshots ]] && mkdir -p ~/Pictures/Screenshots

screenshot_path=~/Pictures/Screenshots/Screenshot_$(date | sed 's/[^[:alnum:]]\+/_/g').jpg

if [[ $1 == "region" ]]; then
    grim -t jpeg -q 85 -g "$(slurp -d)" - | tee $screenshot_path | wl-copy
else
    grim -t jpeg -q 85 - | tee $screenshot_path | wl-copy
fi

