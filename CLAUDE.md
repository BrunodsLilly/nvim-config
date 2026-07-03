# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Neovim Config Reference

Minimal Neovim 0.12 config. Native features first: LSP, Treesitter, `vim.pack`, `vim.opt.autocomplete`, `ui2`.

## Architecture

```
init.lua              -- Entry point: options, leader key, ui2, requires modules
lua/lsp_servers.lua   -- LSP server configs via vim.lsp.config + vim.lsp.enable
lua/lsp_keymaps.lua   -- Keymaps + completion activation on LspAttach
lua/plugins.lua       -- Plugin declarations via vim.pack.add + plugin configs
lua/zettelkasten.lua  -- Second Brain: Vimwiki (navigation) + Telekasten (zettel ops)
lua/markdown_render.lua -- render-markdown.nvim + markdown-preview.nvim + vim-markdown + table tools
lua/snippets.lua      -- Lightweight snippet expander for markdown (CompleteDone + dict source)
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
| `<leader>ft` | n | Find TODOs (Telescope) |
| `<leader>gb` | n | Toggle inline git blame |
| `]h` / `[h` | n | Next/prev git hunk |
| `<leader>ghp` | n | Preview git hunk |
| `<leader>ghs` | n | Stage git hunk |
| `<leader>ghr` | n | Reset git hunk |
| `-` | n | Oil file browser (parent dir) |
| `gd` | n | Go to definition (LSP) |
| `gD` | n | Go to declaration (LSP) |
| `gr` | n | References (LSP) |
| `gi` | n | Go to implementation (LSP) |
| `go` | n | Go to type definition (LSP) |
| `K` | n | Hover docs (LSP) |
| `<C-k>` | i | LSP signature help |
| `<C-space>` | i | Trigger LSP completion |
| `]d` / `[d` | n | Next/prev diagnostic (jump + float) |
| `<leader>e` | n | Show diagnostic float |
| `<leader>q` | n | Diagnostics → quickfix |
| `<leader>rn` | n | LSP rename |
| `<leader>ca` | n | LSP code action |
| `<leader>lwa` | n | LSP add workspace folder |
| `<leader>lwr` | n | LSP remove workspace folder |
| `<leader>lwl` | n | LSP list workspace folders |
| `<C-y>,` | i | Emmet expand abbreviation |
| `<C-j>` | i | Jump to next Emmet edit point |
| `<C-y>k` | i | Jump to prev Emmet edit point (was `<C-k>`, moved to avoid LSP signature_help conflict) |
| `<M-j>` / `<M-k>` | n | Next/prev quickfix item |
| `<M-c>` | n | Close quickfix window |
| `<leader>xq` | n | CWD diagnostics → quickfix |
| `<leader>xx` | n | All diagnostics (Trouble) |
| `<leader>xd` | n | Buffer diagnostics (Trouble) |
| `<leader>xs` | n | Symbols panel (Trouble) |
| `<leader>xl` | n | LSP refs panel (Trouble) |
| `<C-\>` | n/t | Toggle floating terminal |
| `<leader>ev` | n | Edit init.lua (vsplit) |
| `<leader>sv` | n | Source init.lua |
| `<leader>cs` | n | Pick colorscheme |
| `<leader>mr` | n | Toggle in-buffer markdown render |
| `<leader>mp` | n | Toggle markdown preview (browser) |
| `<leader>mP` | n | Start markdown preview |
| `<leader>ms` | n | Stop markdown preview |
| `<leader>Tm` | n | Toggle table mode |
| `<leader>Tr` | n | Realign table |
| `<leader>ww` | n | Vimwiki index |
| `<leader>wi` | n | Vimwiki diary index |
| `<leader>w<leader>w` | n | Today's diary note |
| `<leader>ws` | n | Select wiki |
| `<leader>wn` | n | Go to / create wiki note |
| `<leader>zn` | n | New zettel |
| `<leader>zf` | n | Find notes (Telekasten) |
| `<leader>zg` | n | Grep notes |
| `<leader>zz` | n | Follow link |
| `<leader>zb` | n | Backlinks |
| `<leader>zl` | n | Insert link |
| `<leader>zt` | n | Show tags |
| `<leader>zp` | n | Telekasten command panel |
| `[[` | i | Insert wiki link (Telekasten) |
| `s` / `S` | n/x/o | Flash jump (forward / treesitter) |
| `ys{motion}{char}` | n | Add surround (nvim-surround) |
| `cs{old}{new}` | n | Change surround |
| `ds{char}` | n | Delete surround |
| `<leader>gv` | n | Diffview open |
| `<leader>gV` | n | Diffview close |
| `<leader>gH` | n | File history (current file) |
| `<leader>gL` | n | Branch history |
| `<leader>qs` | n | Restore session for cwd |
| `<leader>ql` | n | Restore last session |
| `<leader>qd` | n | Stop session save |
| `<leader>S` | n | Toggle Spectre (project search/replace) |
| `<leader>sw` | n/v | Spectre: word under cursor / selection |
| `<leader>pr` | n | Octo: PR list |
| `<leader>pc` | n | Octo: PR create |
| `<leader>pR` | n | Octo: PR review start |

## Emmet (Snippets & Abbreviations)

Two systems provide Emmet support:
- **emmet-vim** — manual expand via `<C-y>,` + edit point navigation (`<C-j>` next, `<C-y>k` prev)
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
| todo-comments.nvim | TODO/FIXME/NOTE/HACK highlighting + Telescope search |
| gitsigns.nvim | Signcolumn diff markers, inline EOL blame, hunk ops |
| indent-blankline.nvim | Vertical indent guides + scope highlight |
| nvim-treesitter-context | Sticky function header at top when scrolled |
| which-key.nvim | Keymap discovery popup on leader pause |
| trouble.nvim | Diagnostic/error panel — all errors, buffer errors, symbols, LSP refs |
| toggleterm.nvim | Floating terminal toggle (`<C-\>`) |
| vimwiki | Wiki navigation, diary, markdown file management |
| telekasten.nvim | Zettelkasten ops: new notes, linking, backlinks, tag picker |
| render-markdown.nvim | Obsidian-style in-buffer markdown rendering |
| markdown-preview.nvim | Browser preview with KaTeX math rendering |
| vim-markdown | Folding, frontmatter, math, strikethrough |
| bullets.vim | Smart list continuation on Enter |
| vim-table-mode | ASCII table creation and alignment |
| catppuccin, kanagawa, rose-pine, tokyonight, gruvbox-material | Colorschemes |
| nvim-surround | Add/change/delete surrounding pairs and tags (`ys`/`cs`/`ds`) |
| flash.nvim | Labeled jump motions (`s`/`S`) |
| telescope-fzf-native.nvim | Native fzf sorter for Telescope (auto-built via `PackChanged` autocmd) |
| diffview.nvim | Full repo diff/history viewer |
| octo.nvim | GitHub PR/issue management (`<leader>pr/pc/pR`) |
| persistence.nvim | Session save/restore per cwd |
| nvim-spectre | Project-wide search/replace with preview |

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

## Second Brain (Zettelkasten)

Wiki root: `~/SecondBrain/`. Three vimwiki wikis: default, `work/`, `personal/`.

Telekasten note format: `YYYYMMDDHHMM-title.md` (uuid-title). Templates in `~/SecondBrain/templates/`.

Two systems overlap deliberately — **Vimwiki** handles navigation/diary (Enter to follow links, `<leader>w*`), **Telekasten** handles zettel creation/linking/searching (`<leader>z*`).

`[[` in insert mode triggers Telekasten link picker. Visual selection + `<leader>zl` wraps in `[[link]]`. `<leader>zZ` wraps + follows (creates note).

## Snippets (Markdown)

`lua/snippets.lua` — custom lightweight system (no plugin). On `CompleteDone`, if completed word matches a trigger, replaces with expansion. Triggers appear in autocomplete via dictionary source (`k<path>`).

Triggers: `timeHMS`, `dateISO`, `dateTime`, `timestamp`, `fm` (frontmatter), `h2`, `h3`, `cb` (code block), `task`, `link`.

Active only in `markdown` and `vimwiki` filetypes.

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
- **Keymap namespacing** — LSP workspace ops use `<leader>lw*` (not `<leader>w*`) to avoid Vimwiki clash. Emmet edit-point prev uses `<C-y>k` (not `<C-k>`) to avoid LSP signature_help clash in markup files.
- **Plugin build hooks** — `vim.pack` has no `build` field. Use `PackChanged` autocmd to run post-install commands (see `telescope-fzf-native` block in `plugins.lua`).

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
