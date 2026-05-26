-- Lightweight snippet expander for markdown
-- Triggers appear in autocomplete menu (via dictionary source)
-- On confirm (<C-y>), CompleteDone expands dynamic snippets

local M = {}

-- Snippet definitions: trigger → expansion (string or function)
M.snippets = {
    -- Time/date
    timeHMS = function() return os.date("%H:%M:%S") end,
    dateISO = function() return os.date("%Y-%m-%d") end,
    dateTime = function() return os.date("%Y-%m-%d %H:%M") end,
    timestamp = function() return os.date("%Y%m%d%H%M") end,

    -- Frontmatter
    fm = function()
        return table.concat({
            "---",
            'title: ""',
            string.format("date: %s", os.date("%Y-%m-%d")),
            "type: permanent",
            "tags: []",
            "publish: false",
            "---",
            "",
        }, "\n")
    end,

    -- Structure
    h2 = "## ",
    h3 = "### ",
    cb = "```\n\n```",
    task = "- [ ] ",
    link = "[[]]",
}

-- Write trigger names to dictionary file so autocomplete discovers them
local function write_dictionary()
    local path = vim.fn.stdpath("data") .. "/snippet_triggers.dict"
    local f = io.open(path, "w")
    if f then
        for trigger, _ in pairs(M.snippets) do
            f:write(trigger .. "\n")
        end
        f:close()
    end
    return path
end

-- Replace the just-completed word with snippet expansion
local function expand_completed(word)
    local snippet = M.snippets[word]
    if not snippet then return end

    local expansion = type(snippet) == "function" and snippet() or snippet

    local row = vim.fn.line('.') - 1
    local col = vim.fn.col('.') - 1
    local line = vim.fn.getline('.')

    -- Word sits right before cursor
    local start_col = col - #word
    local before = line:sub(1, start_col)
    local after = line:sub(col + 1)
    local new_text = before .. expansion .. after

    local lines = vim.split(new_text, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(0, row, row + 1, false, lines)

    -- Cursor at end of expansion
    local cursor_line = row + #lines
    local cursor_col = #lines[#lines] - #after
    vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_col })
end

function M.setup()
    local dict_path = write_dictionary()

    -- Add snippet triggers to completion sources for markdown/vimwiki
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "vimwiki" },
        callback = function()
            vim.opt_local.complete:append("k" .. dict_path)
        end,
    })

    -- On CompleteDone: if completed word is a snippet trigger, expand it
    vim.api.nvim_create_autocmd("CompleteDone", {
        callback = function()
            local item = vim.v.completed_item
            if not item or not item.word then return end
            if not M.snippets[item.word] then return end
            vim.schedule(function()
                expand_completed(item.word)
            end)
        end,
    })
end

return M
