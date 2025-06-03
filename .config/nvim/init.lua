vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

local builtin = require("telescope.builtin")

local config = require("nvim-treesitter.configs")

--keymaps--

vim.keymap.set('n', '<C-p>', builtin.find_files,{})
vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left<CR>', {})

config.setup({
    ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
    highlight = {
    enable = true,},
    indent = {enable = true},
})


require("catppuccin").setup()
vim.cmd.colorscheme "catppuccin"
