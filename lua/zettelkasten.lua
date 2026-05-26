-- Zettelkasten Second Brain System
-- Vimwiki (wiki navigation/diary) + Telekasten (zettel creation/linking/search)

local M = {}

function M.setup()
    -- === Vimwiki Configuration ===
    vim.g.vimwiki_list = {
        {
            path = "~/SecondBrain/",
            syntax = "markdown",
            ext = ".md",
            path_html = "~/SecondBrain/html/",
            template_path = "~/SecondBrain/templates/",
            template_default = "default",
            template_ext = ".html",
            auto_tags = 1,
            auto_diary_index = 1,
            auto_generate_links = 1,
            auto_generate_tags = 1,
        },
        {
            path = "~/SecondBrain/work/",
            syntax = "markdown",
            ext = ".md",
            name = "Work Notes",
        },
        {
            path = "~/SecondBrain/personal/",
            syntax = "markdown",
            ext = ".md",
            name = "Personal Growth",
        },
    }

    vim.g.vimwiki_global_ext = 0
    vim.g.vimwiki_conceallevel = 2
    vim.g.vimwiki_markdown_link_ext = 1
    vim.g.vimwiki_auto_chdir = 1
    vim.g.vimwiki_folding = "expr"
    vim.g.vimwiki_auto_header = 1

    -- Vimwiki keymaps
    vim.keymap.set("n", "<leader>ww", "<cmd>VimwikiIndex<cr>", { desc = "Zettelkasten Index" })
    vim.keymap.set("n", "<leader>wi", "<cmd>VimwikiDiaryIndex<cr>", { desc = "Diary Index" })
    vim.keymap.set("n", "<leader>w<leader>w", "<cmd>VimwikiMakeDiaryNote<cr>", { desc = "Today's Diary" })
    vim.keymap.set("n", "<leader>w<leader>y", "<cmd>VimwikiMakeYesterdayDiaryNote<cr>", { desc = "Yesterday's Diary" })
    vim.keymap.set("n", "<leader>w<leader>t", "<cmd>VimwikiMakeTomorrowDiaryNote<cr>", { desc = "Tomorrow's Diary" })
    vim.keymap.set("n", "<leader>ws", "<cmd>VimwikiUISelect<cr>", { desc = "Select Wiki" })
    vim.keymap.set("n", "<leader>wn", "<cmd>VimwikiGoto<cr>", { desc = "Go to/Create Note" })
    vim.keymap.set("n", "<leader>wd", "<cmd>VimwikiDeleteFile<cr>", { desc = "Delete Wiki File" })
    vim.keymap.set("n", "<leader>wr", "<cmd>VimwikiRenameFile<cr>", { desc = "Rename Wiki File" })

    -- Vimwiki buffer-local overrides
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "vimwiki",
        callback = function()
            vim.keymap.set("n", "<leader>wt", "<cmd>VimwikiTable<cr>", { buffer = true, desc = "Create table" })
            vim.keymap.set("n", "<leader>wb", "<cmd>VimwikiBacklinks<cr>", { buffer = true, desc = "Show backlinks" })
            vim.keymap.set("n", "<leader>wg", "<cmd>VimwikiGenerateLinks<cr>", { buffer = true, desc = "Generate links" })
            -- Restore Oil's `-` mapping (Vimwiki hijacks it)
            vim.keymap.set("n", "-", "<cmd>Oil<cr>", { buffer = true, desc = "Open Oil" })
        end,
    })

    -- === Telekasten Configuration ===
    local home = vim.fn.expand("~/SecondBrain")
    require("telekasten").setup({
        home = home,
        take_over_my_home = false,
        auto_set_filetype = true,
        dailies = home .. "/daily",
        weeklies = home .. "/weekly",
        templates = home .. "/templates",
        image_subdir = "images",
        extension = ".md",
        new_note_filename = "uuid-title",
        uuid_type = "%Y%m%d%H%M",
        uuid_sep = "-",
        follow_creates_nonexisting = true,
        dailies_create_nonexisting = true,
        weeklies_create_nonexisting = true,
        journal_auto_open = false,
        template_new_note = home .. "/templates/permanent.md",
        template_new_daily = home .. "/templates/daily.md",
        template_new_weekly = home .. "/templates/weekly.md",
        image_link_style = "markdown",
        sort = "filename",
        plug_into_calendar = false,
        tag_notation = "#",
        command_palette_theme = "dropdown",
        show_tags_theme = "dropdown",
        subdirs_in_links = true,
        template_handling = "smart",
        new_note_location = "smart",
        rename_update_links = true,
    })

    -- Telekasten highlight groups
    vim.api.nvim_set_hl(0, "tkLink", { fg = "#7aa2f7", underline = true })
    vim.api.nvim_set_hl(0, "tkBrackets", { fg = "#565f89" })
    vim.api.nvim_set_hl(0, "tkHighlight", { bg = "#3b4261", fg = "#c0caf5" })
    vim.api.nvim_set_hl(0, "tkTag", { fg = "#9ece6a" })

    -- Telekasten keymaps
    vim.keymap.set("n", "<leader>zn", "<cmd>Telekasten new_note<cr>", { desc = "New Zettel" })
    vim.keymap.set("n", "<leader>zf", "<cmd>Telekasten find_notes<cr>", { desc = "Find Notes" })
    vim.keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<cr>", { desc = "Grep Notes" })
    vim.keymap.set("n", "<leader>zd", "<cmd>Telekasten goto_today<cr>", { desc = "Today's Daily" })
    vim.keymap.set("n", "<leader>zw", "<cmd>Telekasten goto_thisweek<cr>", { desc = "This Week" })
    vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<cr>", { desc = "Follow Link" })
    vim.keymap.set("n", "<leader>zt", "<cmd>Telekasten show_tags<cr>", { desc = "Show Tags" })
    vim.keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<cr>", { desc = "Backlinks" })
    vim.keymap.set("n", "<leader>zl", "<cmd>Telekasten insert_link<cr>", { desc = "Insert Link" })
    vim.keymap.set("n", "<leader>zT", "<cmd>Telekasten tag_picker<cr>", { desc = "Tag Picker" })
    vim.keymap.set("n", "<leader>zr", "<cmd>Telekasten rename_note<cr>", { desc = "Rename Note" })
    vim.keymap.set("n", "<leader>zc", "<cmd>Telekasten show_calendar<cr>", { desc = "Calendar" })
    vim.keymap.set("n", "<leader>zp", "<cmd>Telekasten panel<cr>", { desc = "Command Panel" })
    vim.keymap.set("n", "<leader>zi", "<cmd>Telekasten insert_img_link<cr>", { desc = "Insert Image" })
    vim.keymap.set("n", "<leader>zy", "<cmd>Telekasten yank_notelink<cr>", { desc = "Yank Note Link" })
    vim.keymap.set("n", "<leader>zP", "<cmd>Telekasten paste_img_and_link<cr>", { desc = "Paste Image" })
    vim.keymap.set("n", "<leader>zN", "<cmd>Telekasten new_templated_note<cr>", { desc = "New from Template" })

    -- Insert mode: [[ triggers link insertion
    vim.keymap.set("i", "[[", "<cmd>Telekasten insert_link<cr>", { desc = "Insert Link" })

    -- Visual mode: selection → [[link]]
    vim.keymap.set("v", "<leader>zl", function()
        vim.cmd('normal! "vy')
        local text = vim.fn.getreg('v')
        local timestamp = os.date("%Y%m%d%H%M")
        local normalized = text:gsub("%s+", "-"):lower()
        local link = string.format("[[%s-%s]]", timestamp, normalized)
        vim.cmd('normal! gv')
        vim.cmd('normal! c' .. link)
    end, { desc = "Selection → [[link]]" })

    -- Visual mode: selection → create note + follow
    vim.keymap.set("v", "<leader>zZ", function()
        vim.cmd('normal! "vy')
        local text = vim.fn.getreg('v')
        local timestamp = os.date("%Y%m%d%H%M")
        local normalized = text:gsub("%s+", "-"):lower()
        local link = string.format("[[%s-%s]]", timestamp, normalized)
        vim.cmd('normal! gv')
        vim.cmd('normal! c' .. link)
        vim.cmd('normal! F[')
        vim.defer_fn(function()
            vim.cmd('Telekasten follow_link')
        end, 100)
    end, { desc = "Selection → [[link]] → Follow" })

    -- Normal mode: word under cursor → [[link]]
    vim.keymap.set("n", "<leader>zW", function()
        local word = vim.fn.expand('<cword>')
        local link = string.format("[[%s]]", word:gsub("%s+", "-"):lower())
        vim.cmd('normal! ciw' .. link)
    end, { desc = "Word → [[link]]" })
end

return M
