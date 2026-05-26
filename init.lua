vim.opt.number = true
vim.opt.relativenumber = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.swapfile = false
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
vim.opt.autocomplete = true

require('vim._core.ui2').enable()

vim.keymap.set("n", "<leader>ev", ":vsplit $MYVIMRC<CR>", { desc = "Edit init.lua", silent = true })
vim.keymap.set("n", "<leader>sv", ":source $MYVIMRC | echo 'Configuration reloaded'<CR>", { desc = "Source init.lua", silent = true })

require('lsp_servers').setup()
require('lsp_keymaps').setup()
require('plugins').setup()
require('zettelkasten').setup()
require('markdown_render').setup()
require('snippets').setup()
