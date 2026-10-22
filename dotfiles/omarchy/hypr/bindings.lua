-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.
-- Linked from ~/linux-files/dotfiles/omarchy/hypr/bindings.lua by setup.sh.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Super+Space cycles keyboard layouts (set in input.lua), as before Omarchy.
-- The Omarchy menu moves to Super+D, the old launcher key.
hl.unbind("SUPER + SPACE")
o.bind("SUPER + SPACE", "Next keyboard layout", "hyprctl switchxkblayout all next")
o.bind("SUPER + D", "Omarchy menu", "omarchy-menu toggle")

o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
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
  o.bind("SUPER + SHIFT + " .. key, "Move window " .. dir[2], hl.dsp.window.move({ direction = dir[2], group_aware = true }))
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
