-- LSP server configurations

local M = {}

-- Upward search for a `.venv` starting at pyright's root_dir (typically a
-- monorepo *member* package, e.g. apps/worker-general) so a workspace-root
-- venv one level above (created by `uv sync` at the repo root) is still found.
-- Discovering it this way -- rather than being told about it -- means it
-- keeps working after a `pi --model ...` restart, and for any worktree made
-- by hand, with no per-session remediation.
local function venv_python(start)
    local hits = vim.fs.find('.venv', { path = start, upward = true, type = 'directory', limit = 1 })
    local hit = hits[1]
    if not hit then return nil end
    local python = hit .. '/bin/python'
    return vim.uv.fs_stat(python) and python or nil
end

function M.setup()
    vim.lsp.config('vtsls', {
        cmd = { 'vtsls', '--stdio' },
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
        root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
        settings = {
            typescript = {
                suggest = { autoImports = true },
                inlayHints = {
                    parameterNames = { enabled = 'all' },
                    parameterTypes = { enabled = true },
                    variableTypes = { enabled = true },
                    propertyDeclarationTypes = { enabled = true },
                    functionLikeReturnTypes = { enabled = true },
                },
            },
            javascript = {
                suggest = { autoImports = true },
            },
        },
    })

    vim.lsp.config('lua_ls', {
        cmd = { 'lua-language-server' },
        filetypes = { 'lua' },
        root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
        settings = {
            Lua = {
                runtime = { version = 'LuaJIT' },
                diagnostics = { globals = { 'vim' } },
                workspace = {
                    library = {
                        vim.env.VIMRUNTIME,
                        "${3rd}/luv/library",
                        vim.fn.stdpath("config") .. "/lua",
                    },
                    checkThirdParty = false,
                },
                telemetry = { enable = false },
            },
        },
    })

    vim.lsp.config('pyright', {
        cmd = { 'pyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
        before_init = function(_, config)
            local py = venv_python(config.root_dir or vim.fn.getcwd())
            if py then
                config.settings = vim.tbl_deep_extend('force', config.settings or {}, {
                    python = { pythonPath = py },
                })
            end
        end,
        settings = {
            python = {
                analysis = {
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                    diagnosticMode = 'workspace',
                autoImportCompletions = true,
                },
            },
        },
    })

    vim.lsp.config('ruff', {
        cmd = { 'ruff', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
    })

    vim.lsp.config('gopls', {
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        root_markers = { 'go.mod', 'go.work', '.git' },
        settings = {
            gopls = {
                analyses = {
                    unusedparams = true,
                },
                staticcheck = true,
            },
        },
    })

    vim.lsp.config('html', {
        cmd = { 'vscode-html-language-server', '--stdio' },
        filetypes = { 'html', 'templ' },
        root_markers = { 'package.json', '.git' },
        init_options = {
            provideFormatter = true,
        },
    })

    vim.lsp.config('cssls', {
        cmd = { 'vscode-css-language-server', '--stdio' },
        filetypes = { 'css', 'scss', 'less' },
        root_markers = { 'package.json', '.git' },
        settings = {
            css = { validate = true },
            scss = { validate = true },
            less = { validate = true },
        },
    })

    vim.lsp.config('sourcekit', {
        cmd = { 'sourcekit-lsp' },
        filetypes = { 'swift', 'objective-c', 'objective-cpp' },
        root_markers = { 'Package.swift', '.git' },
    })

    vim.lsp.config('kotlin_language_server', {
        cmd = { 'kotlin-language-server' },
        filetypes = { 'kotlin' },
        root_markers = { 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts', '.git' },
    })

    vim.lsp.config('emmet_language_server', {
        cmd = { 'emmet-language-server', '--stdio' },
        filetypes = { 'html', 'css', 'scss', 'less', 'javascriptreact', 'typescriptreact' },
        root_markers = { '.git' },
    })

    vim.lsp.enable({ 'vtsls', 'lua_ls', 'pyright', 'ruff', 'gopls', 'html', 'cssls', 'emmet_language_server', 'sourcekit', 'kotlin_language_server' })
end

return M
