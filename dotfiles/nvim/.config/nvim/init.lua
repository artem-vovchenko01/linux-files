-- in tools.lua

local cmd = vim.cmd  -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn    -- to call Vim functions e.g. fn.bufnr()
local g = vim.g      -- a table to access global variables
local opt = vim.opt  -- to set options

-- cmd 'packadd paq-nvim'               -- load the package manager
local paq = require('paq') {
    "savq/paq-nvim";
    "neovim/nvim-lspconfig";
    'junegunn/fzf.vim';
    -- "hrsh7th/nvim-compe";
    {'junegunn/fzf', run = fn['fzf#install']};
    'nvim-treesitter/nvim-treesitter';
}
