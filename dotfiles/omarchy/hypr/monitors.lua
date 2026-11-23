-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- HP desk monitors: native resolution, 1.25 zoom.
hl.monitor({ output = "desc:HP Inc. HP Z24u G3", mode = "1920x1200@60", position = "auto", scale = 1.25 })
hl.monitor({ output = "desc:HP Inc. HP 724pu", mode = "1920x1200@60", position = "auto", scale = 1.25 })

-- With an external monitor plugged in, the laptop panel is off; without one, on.
o.launch_on_start(os.getenv("HOME") .. "/linux-files/scripts/tiling-wm/hyprland/omarchy-dock-displays.sh")

-- While ~/.local/state/screen-keep-on exists (Pulpit setting "Keep the screen
-- on"), requests to turn screens off do nothing; the lock screen sends one 5 s
-- after locking. Without a signal the HP 724pu sleeps and cuts its USB hub,
-- and the wired network with it. A short gap is enough to start that sleep.
screen_keep_on_dpms = screen_keep_on_dpms or hl.dsp.dpms
hl.dsp.dpms = function(args)
  local flag = args and args.action == "disable" and io.open(os.getenv("HOME") .. "/.local/state/screen-keep-on")
  if flag then
    flag:close()
    return hl.dsp.exec_cmd("true")
  end
  return screen_keep_on_dpms(args)
end
