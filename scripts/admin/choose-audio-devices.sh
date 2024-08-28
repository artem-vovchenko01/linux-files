#!/usr/bin/env bash
wpctl status | sed -n '/Sinks/,/Filters/{/Filters/q; p}' | cut -d' ' -f3- | grep -vE '^\s*$' | wofi --dmenu | awk '{print $1}' | tr -d "." | wpctl set-default $(cat /dev/stdin)
