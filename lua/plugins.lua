-- Plugin declarations via native vim.pack (Neovim 0.12+)

local M = {}

function M.setup()
    vim.pack.add({
        -- Colorschemes
        'https://github.com/catppuccin/nvim',
        'https://github.com/rebelot/kanagawa.nvim',
        'https://github.com/rose-pine/neovim',
        'https://github.com/folke/tokyonight.nvim',
        'https://github.com/sainnhe/gruvbox-material',
        -- Plugins
        'https://github.com/folke/zen-mode.nvim',
        'https://github.com/nvim-lua/plenary.nvim',
        'https://github.com/nvim-telescope/telescope.nvim',
        'https://github.com/stevearc/oil.nvim',
        'https://github.com/stevearc/conform.nvim',
        'https://github.com/windwp/nvim-autopairs',
        'https://github.com/windwp/nvim-ts-autotag',
        'https://github.com/nvim-treesitter/nvim-treesitter',
        'https://github.com/mattn/emmet-vim',
        'https://github.com/brenoprata10/nvim-highlight-colors',
        -- Zettelkasten / wiki
        'https://github.com/vimwiki/vimwiki',
        'https://github.com/renerocksai/telekasten.nvim',
        'https://github.com/mattn/calendar-vim',
        -- Markdown rendering & editing
        'https://github.com/MeanderingProgrammer/render-markdown.nvim',
        'https://github.com/nvim-tree/nvim-web-devicons',
        'https://github.com/iamcco/markdown-preview.nvim',
        'https://github.com/preservim/vim-markdown',
        'https://github.com/bullets-vim/bullets.vim',
        'https://github.com/dhruvasagar/vim-table-mode',
        -- UX enhancements
        'https://github.com/folke/todo-comments.nvim',
        'https://github.com/lewis6991/gitsigns.nvim',
        'https://github.com/lukas-reineke/indent-blankline.nvim',
        'https://github.com/nvim-treesitter/nvim-treesitter-context',
        'https://github.com/folke/which-key.nvim',
        'https://github.com/folke/trouble.nvim',
        'https://github.com/akinsho/toggleterm.nvim',
        -- Editing & navigation
        'https://github.com/kylechui/nvim-surround',
        'https://github.com/folke/flash.nvim',
        -- Telescope speed
        'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
        -- Git diff viewer
        'https://github.com/sindrets/diffview.nvim',
        -- Agent diff overlay (per-turn review)
        'https://github.com/echasnovski/mini.diff',
        -- GitHub PR/issue management
        'https://github.com/pwntester/octo.nvim',
        -- Session persistence
        'https://github.com/folke/persistence.nvim',
        -- Project search/replace
        'https://github.com/nvim-pack/nvim-spectre',
        -- File tree with LSP diagnostic markers
        'https://github.com/nvim-tree/nvim-tree.lua',
        -- ─── NEW PLUGINS ────────────────────────────────────────────────
        -- Notifications: non-blocking floating messages replace vim.notify
        'https://github.com/rcarriga/nvim-notify',
        -- Statusline: fast, configurable, shows LSP/git/mode
        'https://github.com/nvim-lualine/lualine.nvim',
        -- Buffer tabs at top
        'https://github.com/akinsho/bufferline.nvim',
        -- Comment toggling: BUILT-IN on Neovim 0.10+ (gcc / gc / gco / gcO)
        -- Undo tree visualizer (travel through undo history)
        'https://github.com/mbbill/undotree',
        -- Better text objects (function args, etc.)
        'https://github.com/echasnovski/mini.ai',
        -- Align text (gaip= to align on =)
        'https://github.com/echasnovski/mini.align',
        -- Highlight word under cursor everywhere
        'https://github.com/RRethy/vim-illuminate',
        -- Smooth scrolling
        'https://github.com/karb94/neoscroll.nvim',
        -- Better quickfix window
        'https://github.com/kevinhwang91/nvim-bqf',
        -- Telescope file browser (replace netrw inside telescope)
        'https://github.com/nvim-telescope/telescope-file-browser.nvim',
        -- Git blame in virtual text (full commit, not just gitsigns)
        'https://github.com/f-person/git-blame.nvim',
        -- Yank ring / clipboard history
        'https://github.com/gbprod/yanky.nvim',
    })

    -- Zen Mode
    vim.keymap.set("n", "<leader>z", function()
        require("zen-mode").toggle({
            window = {
                width = 80,
                options = {
                    number = false,
                    relativenumber = false,
                    signcolumn = "no",
                },
            },
        })
    end, { desc = "Toggle Zen Mode", silent = true })

    -- Telescope
    local telescope = function(picker, opts)
        return function() require("telescope.builtin")[picker](opts or {}) end
    end

    vim.keymap.set("n", "<leader>ff", telescope("find_files"), { desc = "Find files", silent = true })
    vim.keymap.set("n", "<leader>fw", telescope("live_grep"), { desc = "Find words", silent = true })
    vim.keymap.set("n", "<leader>fb", telescope("buffers"), { desc = "Find buffers", silent = true })
    vim.keymap.set("n", "<leader>fh", telescope("help_tags"), { desc = "Find help", silent = true })
    vim.keymap.set("n", "<leader>fr", telescope("oldfiles"), { desc = "Recent files", silent = true })
    vim.keymap.set("n", "<leader>fd", telescope("diagnostics"), { desc = "Find diagnostics", silent = true })
    vim.keymap.set("n", "<leader>fs", telescope("lsp_document_symbols"), { desc = "Find symbols", silent = true })
    vim.keymap.set("n", "<leader>fg", telescope("git_status"), { desc = "Git status", silent = true })

    -- Oil
    require("oil").setup()
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory", silent = true })

    -- Conform (autoformatting)
    require("conform").setup({
        formatters_by_ft = {
            javascript = { "prettier" },
            javascriptreact = { "prettier" },
            typescript = { "prettier" },
            typescriptreact = { "prettier" },
            json = { "prettier" },
            yaml = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
            python = { "ruff_format", "ruff_organize_imports" },
            go = { "gofmt", "goimports" },
            kotlin = {},
        },
        format_on_save = function(bufnr)
            if vim.bo[bufnr].filetype == "kotlin" then
                return nil
            end
            return { timeout_ms = 2000, lsp_format = "fallback" }
        end,
    })
    vim.keymap.set("n", "<leader>cf", function()
        require("conform").format({ async = true, lsp_format = "fallback" })
    end, { desc = "Format file", silent = true })

    -- Autopairs (auto-close brackets, quotes, etc.)
    local npairs = require("nvim-autopairs")
    npairs.setup({
        check_ts = true,
    })

    -- Make <CR> between > and </ split into 3 lines with cursor indented in middle
    local Rule = require("nvim-autopairs.rule")
    npairs.add_rules({
        Rule(">", "<", { "html", "typescriptreact", "javascriptreact", "vue", "svelte" })
            :only_cr()
            :use_regex(false),
    })

    -- Treesitter: install missing parsers
    local ts_ok, ts = pcall(require, "nvim-treesitter")
    if ts_ok then
        local installed = require("nvim-treesitter.config").get_installed("parsers")
        local wanted = { "html", "css", "javascript", "typescript", "tsx", "lua", "go", "python", "markdown", "markdown_inline" }
        for _, lang in ipairs(wanted) do
            if not vim.tbl_contains(installed, lang) then
                ts.install(lang)
            end
        end
    end

    -- Treesitter: enable highlighting for any filetype with an installed parser
    vim.api.nvim_create_autocmd("FileType", {
        callback = function()
            local ok, _ = pcall(vim.treesitter.start)
            if not ok then
                -- no parser for this filetype, fall back to regex syntax
                vim.cmd("syntax enable")
            end
        end,
    })

    -- Emmet (abbreviation expander: html:5, div>ul>li*3, etc.)
    vim.g.user_emmet_leader_key = '<C-y>'
    vim.g.user_emmet_install_global = 0
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "html", "css", "scss", "javascriptreact", "typescriptreact" },
        callback = function()
            vim.cmd("EmmetInstall")
            -- Jump to next/prev Emmet edit point.
            -- Note: <C-k> would conflict with LSP signature_help (insert mode), so prev uses <C-y>k.
            vim.keymap.set("i", "<C-j>", "<Plug>(emmet-move-next)", { buffer = true })
            vim.keymap.set("i", "<C-y>k", "<Plug>(emmet-move-prev)", { buffer = true })
        end,
    })

    -- Auto-close HTML/JSX tags
    require("nvim-ts-autotag").setup()

    -- Highlight colors inline (hex, rgb, named colors) + completion menu swatches
    require("nvim-highlight-colors").setup({
        render = "virtual",
        virtual_symbol = "■",
        enable_named_colors = true,
        enable_tailwind = false,
    })

    -- todo-comments
    require("todo-comments").setup()
    vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find TODOs", silent = true })

    -- gitsigns
    require("gitsigns").setup({
        signs = {
            add          = { text = "│" },
            change       = { text = "│" },
            delete       = { text = "_" },
            topdelete    = { text = "‾" },
            changedelete = { text = "~" },
            untracked    = { text = "┆" },
        },
        current_line_blame = true,
        current_line_blame_opts = { virt_text_pos = "eol", delay = 500 },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> · <summary>",
        preview_config = { border = "rounded" },
    })
    vim.keymap.set("n", "<leader>gb",  "<cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle git blame" })
    vim.keymap.set("n", "]h",          function() require("gitsigns").next_hunk() end,    { desc = "Next hunk" })
    vim.keymap.set("n", "[h",          function() require("gitsigns").prev_hunk() end,    { desc = "Prev hunk" })
    vim.keymap.set("n", "<leader>ghp", function() require("gitsigns").preview_hunk() end, { desc = "Preview hunk" })
    vim.keymap.set("n", "<leader>ghs", function() require("gitsigns").stage_hunk() end,   { desc = "Stage hunk" })
    vim.keymap.set("n", "<leader>ghr", function() require("gitsigns").reset_hunk() end,   { desc = "Reset hunk" })

    -- indent-blankline
    require("ibl").setup({
        indent = { char = "│" },
        scope  = { enabled = true, show_start = true, show_end = true },
    })

    -- treesitter-context
    require("treesitter-context").setup({ max_lines = 3 })

    -- which-key
    require("which-key").setup()

    -- trouble.nvim (diagnostic/error panel)
    require("trouble").setup()
    vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                          { desc = "Diagnostics (Trouble)",   silent = true })
    vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",             { desc = "Buffer diagnostics",      silent = true })
    vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",                  { desc = "Symbols (Trouble)",       silent = true })
    vim.keymap.set("n", "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",   { desc = "LSP refs (Trouble)",      silent = true })

    -- toggleterm
    require("toggleterm").setup({ open_mapping = [[<C-\>]], direction = "float" })

    -- nvim-surround: ys/cs/ds for surrounding pairs and tags
    require("nvim-surround").setup()

    -- telescope-fzf-native: native fzf sorter (requires `make` after install)
    -- vim.pack fires PackChanged on install/update; build the C extension automatically.
    vim.api.nvim_create_autocmd("PackChanged", {
        callback = function(ev)
            local data = ev.data or {}
            local spec = data.spec or {}
            if spec.name == "telescope-fzf-native.nvim" and (data.kind == "install" or data.kind == "update") then
                local path = spec.path or data.path
                if path then
                    vim.notify("Building telescope-fzf-native...", vim.log.levels.INFO)
                    vim.system({ "make" }, { cwd = path }, function(out)
                        if out.code == 0 then
                            vim.schedule(function() vim.notify("telescope-fzf-native built", vim.log.levels.INFO) end)
                        else
                            vim.schedule(function() vim.notify("fzf build failed: " .. (out.stderr or ""), vim.log.levels.ERROR) end)
                        end
                    end)
                end
            end
        end,
    })
    pcall(function() require("telescope").load_extension("fzf") end)

    -- flash.nvim: jump anywhere with labeled matches (default: s/S in n/x/o)
    require("flash").setup()

    -- diffview.nvim: full repo diff/history viewer
    require("diffview").setup()
    vim.keymap.set("n", "<leader>gv", "<cmd>DiffviewOpen<cr>",          { desc = "Diffview open",         silent = true })
    vim.keymap.set("n", "<leader>gV", "<cmd>DiffviewClose<cr>",         { desc = "Diffview close",        silent = true })
    vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history (current)", silent = true })
    vim.keymap.set("n", "<leader>gL", "<cmd>DiffviewFileHistory<cr>",   { desc = "Branch history",        silent = true })

    -- mini.diff: per-turn diff overlay for agent review
    local md = require("mini.diff")
    md.setup({
        view = {
            style = "sign",
            signs = { add = "▎", change = "▎", delete = "" },
        },
        mappings = {
            -- Disable default text-object mappings (we'll define our own)
            apply      = "",
            reset      = "",
            textobject = "",
            goto_first = "",
            goto_prev  = "",
            goto_next  = "",
            goto_last  = "",
        },
    })

    -- Save current buffer as new diff reference ("I ack this state")
    vim.keymap.set("n", "<leader>ar", function()
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        -- Set a "manual" source: diff against saved snapshot
        md.set_source(buf, md.gen_source.none())
        vim.b[buf]._mini_diff_ref = lines
        vim.notify("mini.diff: reference set", vim.log.levels.INFO)
    end, { desc = "Set diff reference (ack current state)" })

    -- Toggle diff overlay on/off
    vim.keymap.set("n", "<leader>ad", function()
        md.toggle_overlay(0)
    end, { desc = "Toggle diff overlay" })

    -- Apply hunk under cursor (accept agent change)
    vim.keymap.set("n", "<leader>ah", function()
        md.do_hunks(0, "apply", { scope = "current" })
    end, { desc = "Apply hunk (accept)" })

    -- Reset hunk under cursor (reject agent change)
    vim.keymap.set("n", "<leader>aH", function()
        md.do_hunks(0, "reset", { scope = "current" })
    end, { desc = "Reset hunk (reject)" })


    -- octo.nvim: GitHub PR/issue management
    require("octo").setup()
    vim.keymap.set("n", "<leader>pr", "<cmd>Octo pr list<cr>",     { desc = "PR list",    silent = true })
    vim.keymap.set("n", "<leader>pc", "<cmd>Octo pr create<cr>",   { desc = "PR create",  silent = true })
    vim.keymap.set("n", "<leader>pR", "<cmd>Octo review start<cr>", { desc = "PR review", silent = true })

    -- persistence.nvim: session save/restore per cwd
    require("persistence").setup()
    vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end,                { desc = "Restore session for cwd", silent = true })
    vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore last session",    silent = true })
    vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end,                { desc = "Stop session save",       silent = true })

    -- nvim-spectre: project-wide search/replace with preview
    require("spectre").setup()
    vim.keymap.set("n", "<leader>S",  function() require("spectre").toggle() end,                            { desc = "Toggle Spectre",       silent = true })
    vim.keymap.set("n", "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, { desc = "Spectre word",         silent = true })
    vim.keymap.set("v", "<leader>sw", function() require("spectre").open_visual() end,                       { desc = "Spectre selection",    silent = true })

    -- nvim-tree: NERDTree-style sidebar with LSP diagnostic markers
    -- Errors/warnings bubble up from files to parent directories in the tree.
    require("nvim-tree").setup({
        diagnostics = {
            enable            = true,
            show_on_dirs      = true,  -- propagate markers up to parent folders
            show_on_open_dirs = true,
            debounce_delay    = 50,
            severity = {
                min = vim.diagnostic.severity.WARN,  -- hide hints and info
            },
            icons = {
                hint    = "·",
                info    = "·",
                warning = "ω",
                error   = "Ε",
            },
        },
        renderer = {
            highlight_diagnostics = "name",  -- colour the filename by severity
            icons = {
                diagnostics_placement = "before",
                glyphs = {
                    git = {
                        unstaged  = "Δ",  -- delta  = change
                        staged    = "Σ",  -- sigma  = committed
                        untracked = "Ν",  -- nu     = new
                        deleted   = "Θ",  -- theta  = struck out
                        renamed   = "Ρ",  -- rho    = rename
                        unmerged  = "Μ",  -- mu     = merge
                        ignored   = "Ι",  -- iota   = insignificant
                    },
                },
            },
        },
        view  = { width = 30, side = "left" },
        filters = { dotfiles = false },
        update_focused_file = { enable = true },  -- reveal current file automatically
    })
    vim.keymap.set("n", "<leader>n", "<cmd>NvimTreeFindFileToggle<cr>", { desc = "Toggle file tree (reveal current file)", silent = true })

    -- ═══════════════════════════════════════════════════════════════════════════
    -- NEW PLUGINS SETUP
    -- ═══════════════════════════════════════════════════════════════════════════

    -- nvim-notify: beautiful floating notifications
    local notify = require("notify")
    notify.setup({
        background_colour = "#000000",
        fps = 60,
        render = "compact",
        stages = "fade_in_slide_out",
        timeout = 3000,
        top_down = true,
    })
    vim.notify = notify

    -- lualine: statusline
    require("lualine").setup({
        options = {
            theme = "auto",
            component_separators = { left = "│", right = "│" },
            section_separators = { left = "", right = "" },
            globalstatus = true,
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { { "filename", path = 1 } },
            lualine_x = { "encoding", "fileformat", "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
        },
    })

    -- bufferline: buffer tabs at top
    require("bufferline").setup({
        options = {
            mode = "buffers",
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function(count, level)
                local icon = level:match("error") and "Ε" or "ω"
                return " " .. icon .. " " .. count
            end,
            show_buffer_close_icons = false,
            show_close_icon = false,
            separator_style = "thin",
            offsets = {
                { filetype = "NvimTree", text = "Explorer", text_align = "center" },
            },
        },
    })
    -- Navigate buffers with <S-h> and <S-l>
    vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer", silent = true })
    vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer", silent = true })
    vim.keymap.set("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin buffer", silent = true })
    vim.keymap.set("n", "<leader>bD", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers", silent = true })
    vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer", silent = true })

    -- (Comment toggling is built-in on Neovim 0.10+ — gc/gcc/gco/gcO just work)

    -- undotree: visualize undo history
    vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Toggle Undotree", silent = true })
    -- Persist undo across sessions
    vim.opt.undofile = true
    vim.opt.undodir = vim.fn.stdpath("state") .. "/undo"

    -- mini.ai: better text objects (function args, brackets, quotes, etc.)
    require("mini.ai").setup({
        custom_textobjects = {
            -- f = function args (treesitter), already built-in
            -- a = argument, built-in
        },
        n_lines = 100,
    })

    -- mini.align: align text on characters (ga in visual, then enter char)
    require("mini.align").setup()

    -- vim-illuminate: highlight word under cursor in all visible occurrences
    require("illuminate").configure({
        delay = 200,
        large_file_cutoff = 2000,
        providers = { "lsp", "treesitter", "regex" },
        filetypes_denylist = { "NvimTree", "Trouble", "toggleterm" },
    })
    -- Navigate between illuminated references
    vim.keymap.set("n", "]]", function() require("illuminate").goto_next_reference(false) end, { desc = "Next reference" })
    vim.keymap.set("n", "[[", function() require("illuminate").goto_prev_reference(false) end, { desc = "Prev reference" })

    -- neoscroll: smooth scrolling for <C-u>, <C-d>, zt, zz, zb
    require("neoscroll").setup({
        mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
        hide_cursor = true,
        easing = "quadratic",
    })

    -- nvim-bqf: better quickfix with preview and fzf integration
    require("bqf").setup({
        auto_enable = true,
        preview = {
            auto_preview = true,
            border = "rounded",
            show_title = true,
            winblend = 0,
        },
    })

    -- telescope-file-browser
    pcall(function() require("telescope").load_extension("file_browser") end)
    vim.keymap.set("n", "<leader>fe", "<cmd>Telescope file_browser path=%:p:h select_buffer=true<cr>", { desc = "File browser (cwd)", silent = true })

    -- git-blame: inline git blame with full commit info
    require("gitblame").setup({
        enabled = false,  -- start disabled, toggle with keymap
        date_format = "%Y-%m-%d",
        message_template = "  <author> • <date> • <summary>",
        delay = 500,
    })
    vim.keymap.set("n", "<leader>gB", "<cmd>GitBlameToggle<cr>", { desc = "Toggle git blame (full)", silent = true })

    -- yanky.nvim: yank ring + put cycling
    require("yanky").setup({
        ring = { history_length = 50, storage = "shada" },
        highlight = { on_put = true, on_yank = true, timer = 200 },
    })
    vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
    vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
    vim.keymap.set("n", "<C-p>", "<Plug>(YankyPreviousEntry)", { desc = "Prev yank" })
    vim.keymap.set("n", "<C-n>", "<Plug>(YankyNextEntry)", { desc = "Next yank" })
    vim.keymap.set("n", "<leader>fy", "<cmd>Telescope yank_history<cr>", { desc = "Yank history", silent = true })
    pcall(function() require("telescope").load_extension("yank_history") end)
end

return M
