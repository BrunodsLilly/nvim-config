-- Markdown rendering, preview, and editing enhancements
-- render-markdown.nvim (in-buffer) + markdown-preview.nvim (browser) + bullets + tables

local M = {}

function M.setup()
    -- === render-markdown.nvim: Obsidian-style in-buffer rendering ===
    require("render-markdown").setup({
        enabled = true,
        preset = "obsidian",
        max_file_size = 10.0,

        heading = {
            enabled = true,
            sign = true,
            icons = { "◉ ", "○ ", "✸ ", "✿ ", "▶ ", "▷ " },
            width = "full",
        },

        code = {
            enabled = true,
            sign = true,
            style = "full",
            width = "full",
            left_pad = 2,
            right_pad = 2,
            border = "thin",
        },

        dash = { enabled = true, icon = "─", width = "full" },
        bullet = { enabled = true, icons = { "●", "○", "◆", "◇" } },

        checkbox = {
            enabled = true,
            unchecked = { icon = "󰄱 " },
            checked = { icon = "󰱒 " },
            custom = {
                todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
                important = { raw = "[!]", rendered = "󰀨 ", highlight = "RenderMarkdownHint" },
                question = { raw = "[?]", rendered = "󰘥 ", highlight = "RenderMarkdownWarn" },
            },
        },

        quote = { enabled = true, icon = "▌" },
        table = { enabled = true, style = "full" },

        callout = {
            note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
            tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
            important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
            warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
            caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
        },

        link = {
            enabled = true,
            image = "󰥶 ",
            email = "󰀓 ",
            external = "󰌹 ",
            wiki = { icon = "󱗖 ", highlight = "RenderMarkdownWikiLink" },
        },

        latex = {
            enabled = true,
            converter = "latex2text",
            highlight = "RenderMarkdownMath",
        },

        win_options = {
            conceallevel = { default = vim.o.conceallevel, rendered = 3 },
            concealcursor = { default = vim.o.concealcursor, rendered = "" },
            wrap = { default = true, rendered = true },
        },
    })

    -- Custom highlights
    vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#2d3142", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#2a2d3a", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#272a36", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#1e2030" })
    vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = "#2a2d3a", fg = "#7aa2f7" })
    vim.api.nvim_set_hl(0, "RenderMarkdownWikiLink", { fg = "#9ece6a", underline = true })

    vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle Markdown Rendering" })

    -- === markdown-preview.nvim: Browser preview with KaTeX ===
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_theme = 'dark'
    vim.g.mkdp_filetypes = { 'markdown', 'vimwiki' }
    vim.g.mkdp_page_title = '「${name}」'
    vim.g.mkdp_preview_options = {
        katex = {
            macros = {
                ['\\RR'] = '\\mathbb{R}',
                ['\\NN'] = '\\mathbb{N}',
                ['\\ZZ'] = '\\mathbb{Z}',
                ['\\QQ'] = '\\mathbb{Q}',
                ['\\CC'] = '\\mathbb{C}',
            },
        },
        hide_yaml_meta = 1,
        disable_sync_scroll = 0,
        sync_scroll_type = 'middle',
    }

    vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Toggle Markdown Preview (Browser)" })
    vim.keymap.set("n", "<leader>mP", "<cmd>MarkdownPreview<cr>", { desc = "Start Markdown Preview" })
    vim.keymap.set("n", "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", { desc = "Stop Markdown Preview" })

    -- === vim-markdown: folding, frontmatter, math ===
    vim.g.vim_markdown_folding_disabled = 0
    vim.g.vim_markdown_conceal = 2
    vim.g.vim_markdown_frontmatter = 1
    vim.g.vim_markdown_math = 1
    vim.g.vim_markdown_strikethrough = 1
    vim.g.vim_markdown_new_list_item_indent = 2
    vim.g.vim_markdown_auto_insert_bullets = 1
    vim.g.vim_markdown_toc_autofit = 1

    -- === bullets.vim: smart list continuation ===
    vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit", "vimwiki" }
    vim.g.bullets_enable_in_empty_buffers = 1
    vim.g.bullets_checkbox_markers = " .oOx"
    vim.g.bullets_mapping_leader = "<M-b>"

    -- === vim-table-mode: ASCII table creation ===
    vim.g.table_mode_disable_mappings = 1
    vim.g.table_mode_disable_tableize_mappings = 1
    vim.g.table_mode_corner = "|"
    vim.g.table_mode_align_char = ":"

    vim.keymap.set("n", "<leader>Tm", "<cmd>TableModeToggle<cr>", { desc = "Toggle Table Mode" })
    vim.keymap.set("n", "<leader>Tr", "<cmd>TableModeRealign<cr>", { desc = "Realign Table" })

    -- calendar-vim settings
    vim.g.calendar_monday = 1
    vim.g.calendar_weeknm = 4
end

return M
