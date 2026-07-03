-- LSP keymaps and completion activation
-- Applied on LspAttach

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
            local opts = { buffer = ev.buf, remap = false, silent = true }

            vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })

            -- Native LSP autotrigger only fires on server-declared trigger characters
            -- (e.g. '.'), NOT on identifier letters. Without this, typing `Pat` shows
            -- vim.opt.autocomplete's keyword popup (buffer words, no LSP data), so
            -- accepting with <C-y> can't apply additionalTextEdits (auto-imports).
            -- Per :h vim.lsp.completion.enable() — call get() from InsertCharPre.
            vim.api.nvim_create_autocmd('InsertCharPre', {
                buffer = ev.buf,
                callback = function()
                    if vim.fn.pumvisible() == 1 then return end
                    if vim.v.char:match('[%w_]') then
                        vim.schedule(function() vim.lsp.completion.get() end)
                    end
                end,
            })

            -- Confirm completion with <C-y> so CompleteDone fires reason='accept',
            -- which triggers on_complete_done() and applies additionalTextEdits (auto-imports).
            -- <CR> only uses <C-y> when an item is actively selected (not with noselect default).
            vim.keymap.set('i', '<CR>', function()
                if vim.fn.pumvisible() == 1
                    and vim.fn.complete_info({ 'selected' }).selected ~= -1
                then
                    return '<C-y>'
                end
                return '<CR>'
            end, { expr = true, buffer = ev.buf })

            -- Navigation
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
            vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)

            -- Diagnostics
            vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1,  float = true }) end, opts)
            vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
            vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "<leader>q", vim.diagnostic.setqflist, opts)

            -- Code modifications & documentation
            vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ max_width = 80 }) end, opts)
            vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
            -- Manual LSP completion trigger (persistent dropdown + popup docs per field).
            -- Use inside {} to browse struct fields. Navigate with <C-n>/<C-p>, accept with <C-y>.
            vim.keymap.set("i", "<C-space>", vim.lsp.completion.get, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

            -- Workspace (lw* prefix avoids clash with Vimwiki <leader>w*)
            vim.keymap.set("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, opts)
            vim.keymap.set("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, opts)
            vim.keymap.set("n", "<leader>lwl", function()
                print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, opts)
        end,
    })
end

return M
