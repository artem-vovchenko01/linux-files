#! /bin/bash

source ~/.my-git-os/linux-files/scripts/lib/lib-root.sh

lib system configure-displays-optimal

exit 0

function turn_on_display {
  dispaly=$1
  mode=$2
  scale=$3
  lib run "wlr-randr --output $dispaly --on --mode $mode --scale $scale"
}

function turn_off_display {
  dispaly=$1
  lib run "wlr-randr --output $dispaly --off"
}

wlr-randr | grep -v '^ ' | grep -q HDMI-A-1 &&
{
  turn_on_display HDMI-A-1 2560x1440@74.968002Hz 1
  wlr-randr | grep -v '^ ' | grep -q eDP-1 &&
    turn_off_display eDP-1
} ||
{
  turn_on_display eDP-1 1920x1080@60Hz 1
}
