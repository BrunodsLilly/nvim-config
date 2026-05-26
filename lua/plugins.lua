-- Plugin declarations via native vim.pack (Neovim 0.12+)

local M = {}

function M.setup()
    vim.pack.add({
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
        },
        format_on_save = {
            timeout_ms = 2000,
            lsp_format = "fallback",
        },
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

    -- Treesitter (install parsers for autotag support)
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

    -- Emmet (abbreviation expander: html:5, div>ul>li*3, etc.)
    vim.g.user_emmet_leader_key = '<C-y>'
    vim.g.user_emmet_install_global = 0
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "html", "css", "scss", "javascriptreact", "typescriptreact" },
        callback = function()
            vim.cmd("EmmetInstall")
            -- Jump to next/prev Emmet edit point
            vim.keymap.set("i", "<C-j>", "<Plug>(emmet-move-next)", { buffer = true })
            vim.keymap.set("i", "<C-k>", "<Plug>(emmet-move-prev)", { buffer = true })
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
end

return M
