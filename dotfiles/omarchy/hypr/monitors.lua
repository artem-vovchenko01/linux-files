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

-- While ~/.local/state/screen-keep-on exists (Pulpit setting "Keep monitor
-- awake at lock"), lock screen-off requests black out active external monitors
-- (gamma 0 + DDC brightness 0) instead of DPMS sleep so a monitor's USB hub
-- and wired network stay up. On the laptop panel alone, real DPMS runs.
-- A session that ended blacked out gets its brightness back at start.
o.launch_on_start(os.getenv("HOME") .. "/linux-files/scripts/tiling-wm/hyprland/lock-blackout.sh wake")
screen_keep_on_dpms = screen_keep_on_dpms or hl.dsp.dpms
hl.dsp.dpms = function(args)
  local blackout = os.getenv("HOME") .. "/linux-files/scripts/tiling-wm/hyprland/lock-blackout.sh"
  if args and args.action == "disable" and not args._real then
    local flag = io.open(os.getenv("HOME") .. "/.local/state/screen-keep-on")
    if flag then
      flag:close()
      return hl.dsp.exec_cmd(blackout .. " blank")
    end
  end
  if args and args.action == "enable" then
    os.execute(blackout .. " wake >/dev/null 2>&1 &")
  end
  return screen_keep_on_dpms({ action = args and args.action, output = args and args.output })
end
