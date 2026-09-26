vim.opt.number = true
vim.opt.relativenumber = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.swapfile = false
vim.opt.completeopt = { "menu", "menuone", "noinsert", "popup" }
vim.opt.autocomplete = true

vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

vim.diagnostic.config({
    virtual_text = { prefix = "●" },
    signs = true,
    underline = true,
    severity_sort = true,
})

-- Quickfix navigation
vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>",  { desc = "Next quickfix item",  silent = true })
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>",  { desc = "Prev quickfix item",  silent = true })
vim.keymap.set("n", "<M-c>", "<cmd>cclose<CR>", { desc = "Close quickfix",       silent = true })

-- Collect diagnostics from all CWD buffers into native quickfix
local function cwd_diagnostics_to_qf()
    local cwd = vim.fn.getcwd()
    if cwd:sub(-1) ~= "/" then cwd = cwd .. "/" end
    local items = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name ~= "" and name:sub(1, #cwd) == cwd then
            vim.list_extend(items, vim.diagnostic.toqflist(vim.diagnostic.get(bufnr)))
        end
    end
    vim.fn.setqflist({}, " ", { title = "Diagnostics (cwd)", items = items })
    if #items > 0 then vim.cmd("copen") end
end
vim.keymap.set("n", "<leader>xq", cwd_diagnostics_to_qf, { desc = "CWD diagnostics → quickfix", silent = true })

-- Run pyright CLI over the whole project and load every error into quickfix.
-- Catches errors in files not yet open in any buffer.
local function pyright_to_qf()
    local items = {}
    local stdout_lines = {}
    vim.notify('pyright: checking…', vim.log.levels.INFO)
    vim.fn.jobstart({ 'pyright' }, {
        cwd = vim.fn.getcwd(),
        stdout_buffered = true,
        on_stdout = function(_, data)
            vim.list_extend(stdout_lines, data)
        end,
        on_exit = function()
            for _, line in ipairs(stdout_lines) do
                -- pyright output:  /abs/path/file.py:10:5 - error: message (code)
                local file, lnum, col, sev, msg =
                    line:match('^%s*(.+):(%d+):(%d+) %- (%a+): (.+)$')
                if file then
                    table.insert(items, {
                        filename = file,
                        lnum     = tonumber(lnum),
                        col      = tonumber(col),
                        type     = sev:sub(1, 1):upper(),  -- E or W
                        text     = msg,
                    })
                end
            end
            vim.fn.setqflist({}, ' ', { title = 'pyright', items = items })
            if #items > 0 then
                vim.cmd('copen')
            else
                vim.notify('pyright: no errors ✓', vim.log.levels.INFO)
            end
        end,
    })
end
vim.keymap.set("n", "<leader>xp", pyright_to_qf, { desc = "pyright whole-project → quickfix", silent = true })

-- Replace ~ with space so EndOfBuffer shading shows as solid block (like desert)
vim.opt.fillchars = { eob = " " }

require('vim._core.ui2').enable()

vim.keymap.set("n", "<leader>ev", ":vsplit $MYVIMRC<CR>", { desc = "Edit init.lua", silent = true })
vim.keymap.set("n", "<leader>sv", ":source $MYVIMRC | echo 'Configuration reloaded'<CR>", { desc = "Source init.lua", silent = true })

-- Float windows: rounded border + distinct background
vim.o.winborder = 'rounded'
vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Pmenu' })
vim.api.nvim_set_hl(0, 'FloatBorder', { link = 'PmenuSel' })

-- EndOfBuffer shading: darken Normal bg ~15% so area below last line is visibly tinted
local bit = require('bit')
local function shade_eob()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    local bg = normal.bg
    if bg then
        local r = math.floor(bit.band(bit.rshift(bg, 16), 0xff) * 0.85)
        local g = math.floor(bit.band(bit.rshift(bg,  8), 0xff) * 0.85)
        local b = math.floor(bit.band(bg,                 0xff) * 0.85)
        local shaded = bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b)
        vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = shaded, fg = shaded })
    end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = shade_eob })

-- Colorscheme picker: <leader>cs
local schemes = {
    "catppuccin-mocha", "catppuccin-frappe", "catppuccin-macchiato",
    "kanagawa-wave", "kanagawa-dragon",
    "rose-pine", "rose-pine-moon", "rose-pine-dawn",
    "tokyonight", "tokyonight-night", "tokyonight-storm",
    "gruvbox-material",
    "desert",
}
vim.keymap.set("n", "<leader>cs", function()
    vim.ui.select(schemes, { prompt = "Colorscheme:" }, function(choice)
        if choice then vim.cmd.colorscheme(choice) end
    end)
end, { desc = "Pick colorscheme", silent = true })

if not pcall(vim.cmd.colorscheme, "catppuccin-mocha") then
    vim.cmd.colorscheme("desert")
end

-- nvim-tree requires netrw disabled before plugins load (oil.nvim owns directory
-- opening anyway, so this doesn't regress anything)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

require('lsp_servers').setup()
require('lsp_keymaps').setup()
require('plugins').setup()
require('zettelkasten').setup()
require('markdown_render').setup()
require('snippets').setup()
require('pi_nvim').setup()

-- ═══════════════════════════════════════════════════════════════════════════════
-- Quality-of-life settings
-- ═══════════════════════════════════════════════════════════════════════════════

-- Folding: never start with everything closed. vim-markdown and vimwiki both
-- use expr-based folding, and Neovim's default foldlevel (0) closes every
-- fold on load. foldlevelstart=99 forces folds open regardless of source.
vim.opt.foldlevelstart = 99

-- Smarter search: case-insensitive unless you type a capital
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

-- Faster updates (default 4000ms is sluggish for gitsigns, illuminate, etc.)
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

-- Split behavior: open splits to the right and below (more natural)
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Clipboard: use system clipboard so yank/paste works with macOS
vim.opt.clipboard = "unnamedplus"

-- Mouse: enable for all modes (resize splits, scroll, select)
vim.opt.mouse = "a"

-- Line wrapping: soft-wrap long lines, don't break mid-word
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Persistent marks and better session recovery
vim.opt.shada = "!,'100,<50,s10,h"

-- ═══════════════════════════════════════════════════════════════════════════════
-- Keymaps: window/split navigation
-- ═══════════════════════════════════════════════════════════════════════════════

-- Move between splits with Ctrl+hjkl (no <C-w> prefix needed)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split", silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below split", silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above split", silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split", silent = true })

-- Resize splits with Ctrl+arrows
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height", silent = true })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height", silent = true })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width", silent = true })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width", silent = true })

-- Move lines up/down in visual mode (like VS Code Alt+Up/Down)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Keep cursor centered when searching
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

-- Escape clears search highlighting
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight", silent = true })

-- Quick save
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file", silent = true })

-- Select all
vim.keymap.set("n", "<leader>a", "ggVG", { desc = "Select all", silent = true })

-- Better indenting in visual mode (stay in visual after indent)
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Don't overwrite register when pasting over selection
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without overwrite" })

-- Quick terminal escape
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
