-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.
-- Linked from ~/linux-files/dotfiles/omarchy/hypr/bindings.lua by setup.sh.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Super+Space cycles keyboard layouts (set in input.lua), as before Omarchy,
-- and shows the new one in a large popup at the top (artem.layout-osd plugin).
-- The Omarchy menu moves to Super+D, the old launcher key.
hl.unbind("SUPER + SPACE")
o.bind("SUPER + SPACE", "Next keyboard layout", os.getenv("HOME") .. "/linux-files/scripts/tiling-wm/hyprland/next-keyboard-layout.sh")
o.bind("SUPER + D", "Omarchy menu", "omarchy-menu toggle")

o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })

-- Omarchy's Super+Shift+A opens a ChatGPT web app; rebound below to Pulpit live voice.
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + Q", "Close window", hl.dsp.window.close())

-- Toggle split lost Super+J to vim focus below. Super+V stays paste.
o.bind("SUPER + SHIFT + V", "Toggle window split", hl.dsp.layout("togglesplit"))

-- Replaces Omarchy's top-bar toggle; Super+T still toggles floating too.
hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- Vim keys: focus with Super+H/J/K/L, move with Super+Shift+H/J/K/L.
-- Replaces Omarchy's Super+J (toggle split), Super+K (keybindings help)
-- and Super+L (toggle workspace layout).
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
local vim_keys = {
  H = { "l", "left" },
  J = { "d", "down" },
  K = { "u", "up" },
  L = { "r", "right" },
}
for key, dir in pairs(vim_keys) do
  o.bind("SUPER + " .. key, "Focus " .. dir[2] .. " window", hl.dsp.focus({ direction = dir[1] }))
  -- Super+Shift+K is reserved below for Pulpit's global Ctrl+K palette.
  if key ~= "K" then
    o.bind("SUPER + SHIFT + " .. key, "Move window " .. dir[2], hl.dsp.window.move({ direction = dir[2], group_aware = true }))
  end
end

-- Tabs, like i3/sway "layout tabbed": Super+W makes the window a tab group.
-- Super+N/P switch tabs, Super+Shift+N/P move the tab within the group.
-- Replaces Omarchy's Super+W (close, kept on Super+Shift+Q),
-- Super+P (pseudo), Super+Shift+N (editor), Super+Shift+P (Google Photos).
hl.unbind("SUPER + W")
hl.unbind("SUPER + P")
hl.unbind("SUPER + SHIFT + N")
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + W", "Toggle tab group", hl.dsp.group.toggle())
o.bind("SUPER + N", "Next tab", hl.dsp.group.next())
o.bind("SUPER + P", "Previous tab", hl.dsp.group.prev())
o.bind("SUPER + SHIFT + N", "Move tab forward", hl.dsp.group.move_window({ forward = true }))
o.bind("SUPER + SHIFT + P", "Move tab back", hl.dsp.group.move_window({ forward = false }))

-- Pulpit, the single control panel (~/Projects/pulpit): Super+U focuses its
-- window or opens it on the current workspace.
o.bind("SUPER + U", "Pulpit control panel", os.getenv("HOME") .. "/Projects/pulpit/pulpit-window")

-- Floating Pulpit popup: Super+A opens quick chat and the quick actions of
-- every Pulpit on the active screen; Super+Shift+A snaps the active monitor
-- and starts live voice with smart model/folder routing; Shift+Print captures
-- a region and opens the same popup under it.
o.bind("SUPER + A", "Pulpit quick chat and actions", os.getenv("HOME") .. "/Projects/pulpit/pulpit-ask")
o.bind("SUPER + SHIFT + A", "Pulpit live voice with screen snap", os.getenv("HOME") .. "/Projects/pulpit/pulpit-voice")
o.bind("SUPER + SHIFT + K", "Pulpit global Ctrl+K palette", os.getenv("HOME") .. "/Projects/pulpit/pulpit-palette")
o.bind("SHIFT + PRINT", "Screenshot with AI bar", os.getenv("HOME") .. "/Projects/pulpit/pulpit-shot")

-- Queued system-wide dictation (replaces voxtype's single-flight F9 / Super+Ctrl+X).
hl.unbind("F9")
hl.unbind("SUPER + CTRL + X")
o.bind("F9", "Start dictation (push-to-talk)", os.getenv("HOME") .. "/Projects/pulpit/pulpit-dictate start")
o.bind("F9", "Stop dictation (push-to-talk)", os.getenv("HOME") .. "/Projects/pulpit/pulpit-dictate stop", { release = true })
o.bind("SUPER + CTRL + X", "Toggle dictation", os.getenv("HOME") .. "/Projects/pulpit/pulpit-dictate toggle")
