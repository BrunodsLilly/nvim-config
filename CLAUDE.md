# Neovim Config Reference

Minimal Neovim 0.12 config. Native features first: LSP, Treesitter, `vim.pack`, `vim.opt.autocomplete`, `ui2`.

## Architecture

```
init.lua              -- Entry point: options, leader key, ui2, requires modules
lua/lsp_servers.lua   -- LSP server configs via vim.lsp.config + vim.lsp.enable
lua/lsp_keymaps.lua   -- Keymaps + completion activation on LspAttach
lua/plugins.lua       -- Plugin declarations via vim.pack.add + plugin configs
```

Each `lua/*.lua` module exports `{ setup }`. All called from `init.lua`.

## Keymaps

| Key | Mode | Action |
|-----|------|--------|
| `<Space>` | n | Leader |
| `<leader>ff` | n | Find files |
| `<leader>fw` | n | Live grep (ripgrep) |
| `<leader>fb` | n | Open buffers |
| `<leader>fh` | n | Help tags |
| `<leader>fr` | n | Recent files |
| `<leader>fd` | n | Diagnostics |
| `<leader>fs` | n | Document symbols |
| `<leader>fg` | n | Git status |
| `<leader>cf` | n | Format file |
| `<leader>z` | n | Zen mode toggle |
| `-` | n | Oil file browser (parent dir) |
| `gd` | n | Go to definition (LSP) |
| `gr` | n | References (LSP) |
| `K` | n | Hover docs (LSP) |
| `<C-y>,` | i | Emmet expand abbreviation |
| `<C-j>` | i | Jump to next Emmet edit point |
| `<C-k>` | i | Jump to prev Emmet edit point |

## Emmet (Snippets & Abbreviations)

Two systems provide Emmet support:
- **emmet-vim** — manual expand via `<C-y>,` + edit point navigation (`<C-j>`/`<C-k>`)
- **emmet-language-server** — LSP-driven completions in the dropdown as you type

Active in: html, css, scss, jsx, tsx.

| Abbreviation | Expands to |
|---|---|
| `html:5` | Full HTML5 boilerplate |
| `div>ul>li*3` | Nested div → ul → 3 li |
| `ul>li.item$*5` | ul with li.item1 through li.item5 |
| `.container>header+main+footer` | div.container with 3 children |
| `a[href=#]` | Anchor with href attribute |
| `input:email` | `<input type="email">` |
| `link:css` | Stylesheet link tag |
| `script:src` | Script tag with src attribute |
| `p{Hello}` | `<p>Hello</p>` |
| `m10` (CSS) | `margin: 10px;` |
| `p20-10` (CSS) | `padding: 20px 10px;` |
| `df` (CSS) | `display: flex;` |

Full cheat sheet: https://docs.emmet.io/cheat-sheet/

## Completion System

Two independent systems running together:
- `vim.opt.autocomplete = true` — keyword completion (buffer words)
- `vim.lsp.completion.enable()` — LSP completion with `completionItem/resolve` docs

`completeopt = { "menu", "menuone", "noselect", "popup" }` — `noselect` prevents auto-insert, `popup` shows doc float natively.

## Plugins

| Plugin | Purpose |
|--------|---------|
| telescope.nvim | Fuzzy finder |
| oil.nvim | File browser as buffer |
| conform.nvim | Format on save |
| nvim-autopairs | Auto-close brackets/quotes + tag CR splitting |
| nvim-ts-autotag | Auto-close/rename HTML/JSX tags |
| nvim-treesitter | Parser management (html, css, js, ts, tsx, lua, go, python) |
| emmet-vim | Abbreviation expander + edit point navigation |
| nvim-highlight-colors | Inline color swatches (hex, rgb, named) |
| zen-mode.nvim | Distraction-free writing |

## LSP Servers

| Server | Languages | Install method |
|--------|-----------|----------------|
| `vtsls` | JS/TS/JSX/TSX | `npm i -g @vtsls/language-server` |
| `lua-language-server` | Lua | `brew install lua-language-server` |
| `pyright` | Python (types/completions) | `brew install pyright` |
| `ruff` | Python (lint/format) | `brew install ruff` |
| `gopls` | Go | `brew install gopls` |
| `vscode-html-language-server` | HTML | `brew install vscode-langservers-extracted` |
| `vscode-css-language-server` | CSS/SCSS/Less | `brew install vscode-langservers-extracted` |
| `emmet-language-server` | Emmet completions | `npm i -g @olrtg/emmet-language-server` |

## Formatting (conform.nvim)

Auto-formats on save. Manual: `<leader>cf`

| Filetype | Formatter |
|----------|-----------|
| JS/TS/JSON/YAML/HTML/CSS | prettier |
| Python | ruff_format + ruff_organize_imports |
| Go | gofmt + goimports |

## External Dependencies

```bash
# LSP servers (brew)
brew install lua-language-server pyright ruff gopls vscode-langservers-extracted

# LSP servers (npm via Artifactory)
npm i -g @vtsls/language-server @olrtg/emmet-language-server prettier

# Treesitter compilation
brew install tree-sitter-cli

# Telescope dependencies
brew install ripgrep fd
```

## npm via Artifactory

Public npm registry blocked by company policy. All npm installs route through Lilly Artifactory.

Config: `~/.npmrc`
```
registry=https://elilillyco.jfrog.io/artifactory/api/npm/Lilly-NPM/
//elilillyco.jfrog.io/artifactory/api/npm/Lilly-NPM/:_authToken=<TOKEN>
```

To regenerate expired token:
1. https://elilillyco.jfrog.io/ui/login/ (SAML SSO)
2. Profile → Set Me Up → npm → **Lilly-NPM** → Generate Token
3. Paste new `_authToken` into `~/.npmrc`

## Adding a New Language

1. Add LSP config in `lua/lsp_servers.lua` (vim.lsp.config + add name to vim.lsp.enable)
2. Add treesitter parser to `wanted` list in `lua/plugins.lua`
3. Add formatter in conform.nvim `formatters_by_ft` in `lua/plugins.lua`
4. Install LSP server: `brew install <server>` or `npm i -g <package>`
5. Verify: `nvim --headless -c 'qall' 2>&1` then `:checkhealth lsp`

## Design Decisions

- **Native over plugins** — use built-in features when 0.12 provides them
- **`vim.pack.add`** — native package manager, no bootstrap. Full GitHub URLs. Lockfile at `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`
- **No lazy-loading** — `vim.pack` doesn't support `cmd`/`event`. Use `require()` in callbacks if needed
- **`ui2`** — eliminates "Press ENTER" prompts, highlights cmdline as you type
- **Emmet only in markup files** — `EmmetInstall` called via FileType autocmd, not global
- **Tag CR splitting** — autopairs rule for `>` + `<` splits closing tag to new line on Enter

## vim.pack API

```lua
vim.pack.add({...})   -- list of URL strings or {src=..., name=..., version=...} tables
vim.pack.update()     -- pull latest, shows confirmation buffer
vim.pack.del(name)    -- remove a plugin
vim.pack.get(name)    -- query plugin info
```

## Debugging & Validation

```bash
# Check startup errors
nvim --headless -c 'qall' 2>&1

# Isolate from config
nvim --headless --noplugin -u NONE -c 'lua ...' -c 'qall' 2>&1

# Enumerate object methods
nvim --headless -u NONE -c 'lua for k,v in pairs(vim.THING) do print(k, type(v)) end' -c 'qall'

# Find runtime source for a function
nvim --headless -u NONE -c 'lua print(debug.getinfo(vim.pack.add).source)' -c 'qall'

# Check LSP server capabilities
nvim --headless file.lua -c 'sleep 3' -c 'lua for _,c in ipairs(vim.lsp.get_clients({bufnr=0})) do print(c.name, vim.inspect(c.server_capabilities.completionProvider)) end' -c 'qall'
```

Runtime Lua sources: `/opt/homebrew/Cellar/neovim/<version>/share/nvim/runtime/lua/vim/`

Never trust blog posts. Read the source that ships with your binary.
