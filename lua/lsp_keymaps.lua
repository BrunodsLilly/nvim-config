-- LSP keymaps and completion activation
-- Applied on LspAttach

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
            local opts = { buffer = ev.buf, remap = false, silent = true }

            vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })

            -- Navigation
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
            vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)

            -- Diagnostics
            vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, opts)
            vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, opts)
            vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "<leader>q", vim.diagnostic.setqflist, opts)

            -- Code modifications & documentation
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

            -- Workspace
            vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
            vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
            vim.keymap.set("n", "<leader>wl", function()
                print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, opts)
        end,
    })
end

return M
