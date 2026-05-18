-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

lvim.keys.normal_mode["<C-t>"] = ":ToggleTerm<cr>i"
lvim.keys.normal_mode["<C-n>"] = ":bn<cr>"
lvim.keys.normal_mode["<C-p>"] = ":bp<cr>"
lvim.keys.normal_mode["<C-q>"] = ":BufferKill<cr>"
lvim.keys.normal_mode["<A-e>"] = ":NvimTreeToggle<cr>"
-- "i" at the end is needed to enter Insert mode right away
-- only downside, as I see, it's that "i" get's printed on the first terminal start, and in some other cases occasionally
-- By the way, Ctrl+\ works for toggling terminal out of the box

lvim.keys.term_mode["<C-t>"] = "<C-\\><C-n><C-w>l"
-- see https://www.reddit.com/r/neovim/comments/yzu7cj/comment/ix42a3u/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

lvim.format_on_save.enabled = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = true
lvim.leader = "space"
lvim.colorscheme = "tokyonight-storm"

local transparent_groups = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "SignColumn",
  "EndOfBuffer",
  "MsgArea",
  "WinSeparator",
  "FoldColumn",
  "StatusLine",
  "StatusLineNC",
  "TabLineFill",
  "NvimTreeNormal",
  "NvimTreeNormalNC",
  "NvimTreeEndOfBuffer",
  "TelescopeNormal",
  "TelescopeBorder",
  "TelescopePromptNormal",
  "TelescopePromptBorder",
  "TelescopeResultsNormal",
  "TelescopeResultsBorder",
  "TelescopePreviewNormal",
  "TelescopePreviewBorder",
  "WhichKeyFloat",
}

local function apply_transparent_background()
  for _, group in ipairs(transparent_groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_transparent_background,
})

lvim.plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
  },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "storm",
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
        on_highlights = function(highlights)
          for _, group in ipairs(transparent_groups) do
            highlights[group] = vim.tbl_extend("force", highlights[group] or {}, { bg = "none" })
          end
        end,
      })

      vim.cmd.colorscheme("tokyonight-storm")
      apply_transparent_background()
    end,
  },
  {
    "monkoose/neocodeium",
    event = "VeryLazy",
    cmd = { "NeoCodeium" },
    config = function()
      local neocodeium = require("neocodeium")
      neocodeium.setup()
      vim.keymap.set("i", "<A-f>", neocodeium.accept)
      vim.keymap.set("i", "<A-w>", neocodeium.accept_word)
      vim.keymap.set("i", "<A-a>", neocodeium.accept_line)
      vim.keymap.set("i", "<A-e>", neocodeium.cycle_or_complete)
      vim.keymap.set("i", "<A-r>", function() neocodeium.cycle_or_complete(-1) end)
      vim.keymap.set("i", "<A-c>", neocodeium.clear)
    end,
  },
}

-- lvim.g.indent_blankline_use_treesitter = false
-- lvim.builtin.treesitter.indent = { enable = false }

-- disable Treesitter's indent module globally
-- vim.builtin.treesitter.indent = { enable = false }

-- also stop indent-blankline from querying Treesitter (avoids that crash path)
-- im.g.indent_blankline_use_treesitter = false
