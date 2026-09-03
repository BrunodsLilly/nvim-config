local M = {}

local ns = vim.api.nvim_create_namespace("pi_nvim")

-- Deliberately NO global socket-pointer file.
--
-- This module used to publish vim.v.servername to
-- ~/.pi/agent/runtime/nvim-server.txt on VimEnter and BufEnter so that any pi
-- process could find "the" Neovim. With more than one Neovim -- or more than one
-- agent -- that file is last-buffer-touched-wins: a private `nvim --listen`
-- session spawned for one agent still advertised its own socket globally, and a
-- second agent with no $NVIM would silently attach to it. Observed live, not
-- hypothetical: the pointer flipped mid-session to another agent's private
-- socket, leaving that agent one `/nvim-mode on` away from driving someone
-- else's editor.
--
-- So the pointer is gone, and pi resolves exactly one candidate ($NVIM) with no
-- fallback. A Neovim started by hand is therefore NOT discoverable by an
-- unrelated pi process, by design. The two supported ways to pair them:
--   * run pi from a :terminal inside Neovim ($NVIM is set by Neovim itself), or
--   * /nvim-window, which spawns the pair on a private socket and stamps
--     g:pi_owner so each side can prove it reached its own partner.

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

function M.servername()
    return vim.v.servername
end

--- The ownership token stamped by /nvim-window via --cmd "let g:pi_owner=...".
--- nil for a hand-started Neovim, which is fine: in that case $NVIM can only
--- have been set by this very Neovim for its own child processes.
function M.owner()
    local owner = vim.g.pi_owner
    return (type(owner) == "string" and owner ~= "") and owner or nil
end

-- ===========================================================================
-- ASK CHANNEL: push a question (with a selection) back to the paired pi
--
-- pi publishes its own RPC channel id as g:pi_chan when /nvim-mode on runs, and
-- we notify that channel directly. Targeted, not broadcast: nvim_subscribe was
-- removed in 0.12, so rpcnotify(0, ...) reaches nobody, and targeting the exact
-- channel also means only the pi paired with THIS Neovim ever hears it.
-- ===========================================================================

local function pi_channel()
    local chan = vim.g.pi_chan
    if type(chan) ~= "number" or chan <= 0 then
        return nil, "No pi is listening (g:pi_chan unset). Run /nvim-mode on in the pi pane."
    end
    return chan, nil
end

--- Which gitsigns hunks overlap [first, last]?
---
--- Returns nil when gitsigns isn't loaded, isn't attached to this buffer (the
--- normal case outside a repo), or when nothing in range has changed — all of
--- which simply mean "no diff context to add", not an error.
local function hunks_in_range(bufnr, first, last)
    local ok, gs = pcall(require, "gitsigns")
    if not ok or type(gs.get_hunks) ~= "function" then
        return nil
    end

    local hunks = gs.get_hunks(bufnr)
    if not hunks then
        return nil
    end

    local found = {}
    for _, h in ipairs(hunks) do
        local added = h.added or {}
        local hs = added.start or 0
        -- A pure deletion has count 0 and sits *at* one line rather than
        -- spanning any, so collapse it to a single-line span instead of letting
        -- hs..hs-1 make the overlap test always fail.
        local he = (added.count and added.count > 0) and (hs + added.count - 1) or hs
        if not (he < first or hs > last) then
            found[#found + 1] = { head = h.head, type = h.type, lines = h.lines }
        end
    end

    return #found > 0 and found or nil
end

--- "branch@sha" for the repo owning `path`, or nil outside a repo. Only called
--- when there is diff context worth labelling, since it costs two subprocesses.
local function git_head(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end
    local dir = vim.fn.fnamemodify(path, ":h")
    local branch = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--abbrev-ref", "HEAD" })[1]
    if vim.v.shell_error ~= 0 or not branch then
        return nil
    end
    local sha = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--short", "HEAD" })[1]
    return sha and (branch .. "@" .. sha) or branch
end

--- Where the question is being asked from, so pi can frame its answer.
--- "diffview" and "diff" mean the lines on screen are a *comparison*, not the
--- current file, which changes what "this code" even refers to.
local function view_context(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name:match("^diffview://") then
        return "diffview"
    end
    if vim.wo.diff then
        return "diff"
    end
    return "buffer"
end

--- Sends a question plus a line range to pi.
---
--- Both the range and the selected text go over the wire: the range is
--- authoritative (pi can re-read the file), the text records what was actually
--- on screen when the question was asked.
---
--- @param opts table line1, line2 (1-indexed inclusive), optional question
function M.ask(opts)
    opts = opts or {}
    local chan, err = pi_channel()
    if not chan then
        vim.notify(err, vim.log.levels.WARN, { title = "pi" })
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local first = math.max(1, opts.line1 or vim.fn.line("."))
    local last = math.max(first, opts.line2 or first)
    local lines = vim.api.nvim_buf_get_lines(bufnr, first - 1, last, false)
    local path = current_buf_path(bufnr)

    local function deliver(question)
        -- vim.ui.input yields nil when cancelled with <Esc>; an empty string when
        -- submitted blank. Neither should wake the agent.
        if type(question) ~= "string" or vim.trim(question) == "" then
            vim.notify("pi: cancelled", vim.log.levels.INFO, { title = "pi" })
            return
        end

        local hunks = hunks_in_range(bufnr, first, last)

        local ok, notify_err = pcall(vim.rpcnotify, chan, "pi_ask", {
            question = question,
            path = path,
            start_line = first,
            end_line = last,
            lines = lines,
            filetype = vim.bo[bufnr].filetype,
            -- Diff context, only when there is any: its absence is how pi tells
            -- "explain this code" from "why did this change". git_head costs two
            -- subprocesses, so it is skipped unless a hunk made it relevant.
            context = view_context(bufnr),
            hunks = hunks,
            git = hunks and git_head(path) or nil,
        })

        if not ok then
            -- The channel id was stale: pi exited without clearing g:pi_chan.
            -- Clear it ourselves so the next :PiAsk gives the useful message
            -- instead of failing the same way again.
            vim.g.pi_chan = nil
            vim.notify(
                "pi: channel " .. chan .. " is gone (" .. tostring(notify_err) .. ").\n"
                    .. "Re-run /nvim-mode on in the pi pane.",
                vim.log.levels.ERROR,
                { title = "pi" }
            )
            return
        end

        local where = (path or "buffer") .. ":" .. first .. (last > first and ("-" .. last) or "")
        vim.notify(
            "Sent to pi → "
                .. where
                .. " ("
                .. #lines
                .. " line"
                .. (#lines == 1 and "" or "s")
                .. (hunks and (", " .. #hunks .. " hunk" .. (#hunks == 1 and "" or "s")) or "")
                .. ")",
            vim.log.levels.INFO,
            { title = "pi" }
        )
    end

    if type(opts.question) == "string" and vim.trim(opts.question) ~= "" then
        deliver(opts.question)
    else
        local span = first == last and ("line " .. first) or ("lines " .. first .. "-" .. last)
        vim.ui.input({ prompt = "Ask pi about " .. span .. ": " }, deliver)
    end
end

--- Sends the quickfix (or location) list to pi as a set of places to look at.
---
--- The natural partner to `:Gitsigns setqflist all`, which fills quickfix with
--- every changed hunk in the repo: fill the list with whatever you care about,
--- then hand the whole list over with one question attached. Also works for
--- diagnostics, grep hits, or an LSP reference list.
---
--- @param opts table loclist (boolean), optional question
function M.send_list(opts)
    opts = opts or {}
    local chan, err = pi_channel()
    if not chan then
        vim.notify(err, vim.log.levels.WARN, { title = "pi" })
        return
    end

    local raw, meta
    if opts.loclist then
        raw = vim.fn.getloclist(0)
        meta = vim.fn.getloclist(0, { title = 1 })
    else
        raw = vim.fn.getqflist()
        meta = vim.fn.getqflist({ title = 1 })
    end

    if #raw == 0 then
        vim.notify(
            (opts.loclist and "Location" or "Quickfix") .. " list is empty — nothing to send.",
            vim.log.levels.WARN,
            { title = "pi" }
        )
        return
    end

    -- Quickfix entries carry a bufnr, not a path, and bufname('') is "" for the
    -- synthetic entries some producers emit; keep those but leave the path blank
    -- rather than dropping the line, since the text is often the useful part.
    local items = {}
    for _, e in ipairs(raw) do
        items[#items + 1] = {
            path = (e.bufnr and e.bufnr > 0) and vim.api.nvim_buf_get_name(e.bufnr) or (e.filename or ""),
            lnum = e.lnum or 0,
            col = e.col or 0,
            text = vim.trim(e.text or ""),
            type = e.type or "",
        }
    end

    local function deliver(question)
        if type(question) ~= "string" or vim.trim(question) == "" then
            vim.notify("pi: cancelled", vim.log.levels.INFO, { title = "pi" })
            return
        end
        local ok, notify_err = pcall(vim.rpcnotify, chan, "pi_list", {
            question = question,
            kind = opts.loclist and "loclist" or "quickfix",
            title = meta and meta.title or "",
            items = items,
        })
        if not ok then
            vim.g.pi_chan = nil
            vim.notify(
                "pi: channel " .. chan .. " is gone (" .. tostring(notify_err) .. ").\n"
                    .. "Re-run /nvim-mode on in the pi pane.",
                vim.log.levels.ERROR,
                { title = "pi" }
            )
            return
        end
        vim.notify("Sent " .. #items .. " list item(s) to pi", vim.log.levels.INFO, { title = "pi" })
    end

    if type(opts.question) == "string" and vim.trim(opts.question) ~= "" then
        deliver(opts.question)
    else
        vim.ui.input({ prompt = "Ask pi about these " .. #items .. " place(s): " }, deliver)
    end
end

-- ===========================================================================
-- PER-TURN DIFF REFERENCE (mini.diff)
--
-- Canonical home for the "diff against this exact state" sequence, so the
-- <leader>ar keymap and pi's own per-turn marking share one implementation
-- instead of two copies of a fiddly three-step dance.
--
-- Ordering is load-bearing and every violation fails silently:
--   1. source must be gen_source.none() BEFORE enabling. enable() attaches the
--      configured source, defaulting to gen_source.git, which fails outside a
--      repo (so the buffer never enables) and inside one would immediately
--      overwrite the snapshot.
--   2. buffer-local config is only read at enable time, so an already-tracked
--      buffer must be disabled and re-enabled.
--   3. set_ref_text() refuses a buffer that is not enabled, so it goes last.
-- ===========================================================================

--- Pin the diff reference to a buffer's current contents.
--- @return boolean ok, string|number detail  line count on success, message on failure
function M.ack_state(buf)
    local ok_md, md = pcall(require, "mini.diff")
    if not ok_md then
        return false, "mini.diff is not available"
    end

    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    vim.b[buf].minidiff_config = { source = md.gen_source.none() }
    if md.get_buf_data(buf) ~= nil then
        pcall(md.disable, buf)
    end

    local ok_enable, enable_err = pcall(md.enable, buf)
    if not ok_enable then
        return false, "enable: " .. tostring(enable_err)
    end

    local ok_ref, ref_err = pcall(md.set_ref_text, buf, lines)
    if not ok_ref then
        return false, "set_ref_text: " .. tostring(ref_err)
    end

    return true, #lines
end

--- Hand a buffer back to the git source (undoes ack_state).
function M.track_git(buf)
    local ok_md, md = pcall(require, "mini.diff")
    if not ok_md then
        return false, "mini.diff is not available"
    end

    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    vim.b[buf].minidiff_config = nil
    if md.get_buf_data(buf) ~= nil then
        pcall(md.disable, buf)
    end

    local ok, err = pcall(md.enable, buf)
    return ok, ok and "tracking git" or tostring(err)
end

--- Called by pi before it edits a file: pins the reference to the pre-edit state
--- so the overlay afterwards shows exactly what this turn changed. Takes a path
--- rather than a buffer because pi thinks in paths, and silently does nothing if
--- the file isn't open — there is no visible diff to annotate in that case.
function M.mark_turn_reference(path)
    if type(path) ~= "string" or path == "" then
        return false, "no path"
    end
    local buf = vim.fn.bufnr(path)
    if buf == -1 or not vim.api.nvim_buf_is_loaded(buf) then
        return false, "not open"
    end
    return M.ack_state(buf)
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
        server = vim.v.servername,
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
    -- :PiAsk works with or without a range. From visual mode the `:` prefix
    -- supplies '<,'> automatically, so the visual keymap below needs no extra
    -- work. With no range at all, line1 == line2 == the cursor line.
    vim.api.nvim_create_user_command("PiAsk", function(a)
        M.ask({ line1 = a.line1, line2 = a.line2, question = a.args })
    end, {
        range = true,
        nargs = "*",
        desc = "Ask the paired pi about this range (prompts if no question given)",
    })

    -- Visual mode only, and deliberately NOT under <leader>p: <leader>p is
    -- already "paste without overwrite" in visual mode, so any <leader>p* here
    -- would make every paste wait to see if another key is coming.
    vim.keymap.set("x", "<leader>a", ":PiAsk<CR>", {
        silent = true,
        desc = "Ask pi about the selection",
    })

    -- Send the quickfix list (or, with !, the window's location list) to pi.
    vim.api.nvim_create_user_command("PiSendList", function(a)
        M.send_list({ loclist = a.bang, question = a.args })
    end, {
        bang = true,
        nargs = "*",
        desc = "Send the quickfix list (PiSendList! = loclist) to pi with a question",
    })

    -- The pairing this is designed for: every changed hunk in the repo, then
    -- hand the whole list to pi. <leader>gq fills it, <leader>gQ ships it.
    vim.keymap.set("n", "<leader>gQ", "<cmd>PiSendList<CR>", {
        silent = true,
        desc = "Send quickfix list to pi",
    })

    vim.api.nvim_create_user_command("PiNvimServer", function()
        local server = vim.v.servername
        if type(server) ~= "string" or server == "" then
            vim.notify(
                "No servername: this Neovim has no RPC socket, so pi cannot attach.\n"
                    .. "Start it with `nvim --listen <path>` (or use /nvim-window).",
                vim.log.levels.WARN
            )
            return
        end
        vim.notify(
            ("servername: %s\nowner: %s\npi channel: %s\nPoint pi at it with NVIM=%s"):format(
                server,
                M.owner() or "(none -- hand-started)",
                vim.g.pi_chan or "(none -- /nvim-mode on not run)",
                server
            ),
            vim.log.levels.INFO
        )
    end, { desc = "Show the socket path and owner token Pi should attach to" })

    vim.api.nvim_create_user_command("PiNvimContext", function()
        local ctx = M.current_context()
        M.show_markdown("Pi Neovim Context", vim.inspect(ctx), { kind = "split" })
    end, { desc = "Inspect the current Neovim context exported to Pi" })
end

return M
