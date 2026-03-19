#!/usr/bin/env bash

awk '
/^SwapTotal:/ { total = $2 / 1048576 }
/^SwapFree:/ { free = $2 / 1048576 }
END {
    used = total - free
    if (used < 0) {
        used = 0
    }

    if (total <= 0) {
        percentage = 0
        tier = 0
        tooltip = "Swap disabled"
    } else {
        percentage = int((used / total) * 100 + 0.5)
        tier = int(percentage / 10)
        if (tier > 9) {
            tier = 9
        }
        tooltip = sprintf("%.1f/%.1f G swap (%d%%)", used, total, percentage)
    }

    printf("{\"text\":\"%.1f/%.1f G\",\"tooltip\":\"%s\",\"class\":\"load%d\",\"percentage\":%d}\n", used, total, tooltip, tier, percentage)
}
' /proc/meminfo
