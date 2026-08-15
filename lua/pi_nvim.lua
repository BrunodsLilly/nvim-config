local M = {}

local ns = vim.api.nvim_create_namespace("pi_nvim")
local runtime_dir = vim.fn.expand("~/.pi/agent/runtime")
local socket_file = runtime_dir .. "/nvim-server.txt"

local function ensure_runtime_dir()
    vim.fn.mkdir(runtime_dir, "p")
end

local function write_socket_file()
    local server = vim.v.servername
    if type(server) ~= "string" or server == "" then
        return nil
    end
    ensure_runtime_dir()
    vim.fn.writefile({ server }, socket_file)
    return server
end

local function current_buf_path(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    return name ~= "" and name or nil
end

local function make_pos(line, col)
    return { line = line, col = col }
end

local function visual_range(bufnr)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    if start_pos[2] == 0 or end_pos[2] == 0 then
        return nil
    end

    local s_line = start_pos[2] - 1
    local s_col = start_pos[3] - 1
    local e_line = end_pos[2] - 1
    local e_col = end_pos[3]

    if s_line > e_line or (s_line == e_line and s_col > e_col) then
        s_line, e_line = e_line, s_line
        s_col, e_col = e_col, s_col
    end

    local mode = vim.fn.visualmode()
    if mode == "V" then
        s_col = 0
        local end_line = vim.api.nvim_buf_get_lines(bufnr, e_line, e_line + 1, false)[1] or ""
        e_col = #end_line
    elseif mode == "\022" then
        -- Blockwise mode is represented as a rectangular range, but we still return
        -- the linewise text slice for simplicity.
        if s_col > e_col then s_col, e_col = e_col, s_col end
    end

    return {
        start = make_pos(s_line, s_col),
        ["end"] = make_pos(e_line, math.max(s_col, e_col)),
        mode = mode,
    }
end

local function selection_text(bufnr, range)
    if not range then return nil end
    local lines = vim.api.nvim_buf_get_text(
        bufnr,
        range.start.line,
        range.start.col,
        range["end"].line,
        range["end"].col,
        {}
    )
    return table.concat(lines, "\n")
end

local function serialize_diagnostics(diags)
    local out = {}
    for _, diag in ipairs(diags) do
        out[#out + 1] = {
            line = diag.lnum + 1,
            col = diag.col + 1,
            end_line = (diag.end_lnum or diag.lnum) + 1,
            end_col = (diag.end_col or diag.col) + 1,
            severity = vim.diagnostic.severity[diag.severity] or diag.severity,
            message = diag.message,
            source = diag.source,
            code = diag.code,
        }
    end
    return out
end

local function context_lines(bufnr, center_line, radius)
    local start_line = math.max(0, center_line - radius)
    local end_line = math.min(vim.api.nvim_buf_line_count(bufnr), center_line + radius + 1)
    return {
        start_line = start_line + 1,
        lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false),
    }
end

function M.socket_file()
    return socket_file
end

function M.servername()
    return write_socket_file() or vim.v.servername
end

function M.visual_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local range = visual_range(bufnr)
    if not range then
        return nil
    end
    return {
        bufnr = bufnr,
        path = current_buf_path(bufnr),
        range = range,
        text = selection_text(bufnr, range),
    }
end

function M.current_context(opts)
    opts = opts or {}
    local radius = opts.radius or 30
    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local row = cursor[1] - 1
    local col = cursor[2]
    local path = current_buf_path(bufnr)

    local ok_clients, clients = pcall(vim.lsp.get_clients, { bufnr = bufnr })
    local lsp_clients = {}
    if ok_clients and clients then
        for _, client in ipairs(clients) do
            lsp_clients[#lsp_clients + 1] = client.name
        end
    end

    return {
        server = write_socket_file() or vim.v.servername,
        cwd = vim.fn.getcwd(),
        mode = vim.fn.mode(),
        win = win,
        bufnr = bufnr,
        path = path,
        filetype = vim.bo[bufnr].filetype,
        modified = vim.bo[bufnr].modified,
        readonly = vim.bo[bufnr].readonly,
        cursor = make_pos(row, col),
        visible_range = {
            start_line = vim.fn.line("w0"),
            end_line = vim.fn.line("w$"),
        },
        diagnostics = serialize_diagnostics(vim.diagnostic.get(bufnr)),
        lsp_clients = lsp_clients,
        around_cursor = context_lines(bufnr, row, radius),
        selection = M.visual_selection(),
    }
end

function M.show_markdown(title, text, opts)
    opts = opts or {}
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = {}
    if title and title ~= "" then
        lines[#lines + 1] = "# " .. title
        lines[#lines + 1] = ""
    end
    for s in (text or ""):gmatch("([^\n]*)\n?") do
        lines[#lines + 1] = s
    end
    if #lines > 0 and lines[#lines] == "" then
        table.remove(lines)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false

    if opts.kind == "split" then
        vim.cmd("belowright split")
        vim.api.nvim_win_set_buf(0, buf)
        return { bufnr = buf, winid = vim.api.nvim_get_current_win(), kind = "split" }
    end

    local width = math.min(opts.width or math.max(60, math.floor(vim.o.columns * 0.7)), vim.o.columns - 4)
    local height = math.min(opts.height or math.max(8, math.floor(vim.o.lines * 0.6)), vim.o.lines - 4)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = opts.border or "rounded",
        title = title,
        title_pos = "center",
    })
    return { bufnr = buf, winid = win, kind = "float" }
end

function M.scratch(title, lines, opts)
    opts = opts or {}
    local buf = vim.api.nvim_create_buf(true, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_name(buf, title and ("scratch://" .. title) or "scratch://pi")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or {})
    if opts.filetype then
        vim.bo[buf].filetype = opts.filetype
    end

    local open = opts.open or "vsplit"
    if open == "current" then
        vim.api.nvim_win_set_buf(0, buf)
    elseif open == "split" then
        vim.cmd("belowright split")
        vim.api.nvim_win_set_buf(0, buf)
    elseif open == "tab" then
        vim.cmd("tabnew")
        vim.api.nvim_win_set_buf(0, buf)
    else
        vim.cmd("belowright vsplit")
        vim.api.nvim_win_set_buf(0, buf)
    end

    if title and title ~= "" then
        vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "# " .. title, "" })
        if lines and #lines > 0 then
            vim.api.nvim_buf_set_lines(buf, 2, -1, false, lines)
        end
    end

    return { bufnr = buf, winid = vim.api.nvim_get_current_win() }
end

function M.set_qf(items, title)
    vim.fn.setqflist({}, " ", { title = title or "Pi", items = items or {} })
    if items and #items > 0 then
        vim.cmd("copen")
    end
    return { count = items and #items or 0, title = title or "Pi" }
end

function M.set_loclist(items, title, winid)
    winid = winid or 0
    vim.fn.setloclist(winid, {}, " ", { title = title or "Pi", items = items or {} })
    if items and #items > 0 then
        vim.cmd("lopen")
    end
    return { count = items and #items or 0, title = title or "Pi", winid = winid }
end

function M.mark_range(bufnr, start_line, start_col, end_line, end_col, opts)
    opts = opts or {}
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local id = vim.api.nvim_buf_set_extmark(bufnr, ns, start_line, start_col, {
        end_row = end_line,
        end_col = end_col,
        hl_group = opts.hl_group or "Visual",
        virt_text = opts.virt_text and { { opts.virt_text, opts.virt_text_hl or "Comment" } } or nil,
        virt_text_pos = opts.virt_text_pos or "eol",
        right_gravity = false,
    })
    return { id = id, bufnr = bufnr }
end

function M.clear_marks(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    return { bufnr = bufnr }
end

function M.setup()
    write_socket_file()

    vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
        callback = function()
            write_socket_file()
        end,
    })

    vim.api.nvim_create_user_command("PiNvimServer", function()
        local server = write_socket_file() or ""
        vim.notify(server ~= "" and server or "No active servername", vim.log.levels.INFO)
    end, { desc = "Show the socket path Pi should attach to" })

    vim.api.nvim_create_user_command("PiNvimContext", function()
        local ctx = M.current_context()
        M.show_markdown("Pi Neovim Context", vim.inspect(ctx), { kind = "split" })
    end, { desc = "Inspect the current Neovim context exported to Pi" })
end

return M
