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
