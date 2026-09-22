# Neovim Config: Finish the Idiomatic Improvements

## Problem Statement

`improvements.md` records a prior review of every file under `config/nvim/`. Several
findings have since been fixed (the treesitter augroup wipe, the `local init_result`
leak, the unbounded `close_tabs_to_right` loop, the `ShowSnippets` sink ordering, the
redundant `VimPlug.source()` call), but most of the review is still unaddressed.

The remaining work falls into four buckets:

1. **Dead and misleading code.** `map.lua` is a 68-line reimplementation of
   `vim.keymap.set` in which more than half the wrappers have zero callers; `util.lua`
   carries an unused 28-line `truncate_center` and a `print_current_filetype` that is
   reachable only through a `_G` alias; `vim_plug.install_plugins` is self-documented as
   untested and unused; `lsp_clangd.lua` is 15 lines of commented-out mappings;
   `vim.sequential_glance_fallback` is not a real variable.

2. **A global namespace leak.** `globals.lua` publishes eight functions onto `_G` purely
   so that string mappings such as `':lua copy_file_and_line()<cr>'` can reach them, and
   `init.lua` keeps a `_G.config_loaded` reload flag in the global namespace.

3. **Triplicated and non-idiomatic structure.** The three `lsp_*.lua` files are ~90%
   identical, each creating its own `LspAttach` autocmd and its own near-identical
   mapping set. `plugins.lua` iterates its plugin table with `pairs()` twice, so plugin
   load order is nondeterministic, and it mutates the static config table with an
   `initialized` field.

4. **No way to reconcile the two editors.** `map.lua` deliberately mirrors Vim mapping
   command names so that mappings can be copy/pasted between `config/nvim/` and
   `config/vimrc`. The two files have already drifted: `config/vimrc` has no
   `<leader><tab>n`/`p`/`q`, no `<leader>bd` ordering parity, no `telescope` mappings,
   and uses `:Tags` where Neovim uses both `:Tags` and `:Telescope tags`. There is no
   mechanism to detect or reconcile the drift.

Why it matters: the dead code and `_G` bridge make the config hard to reason about, the
`pairs()` iteration makes plugin load order an accident, and the Vim/Neovim drift is
invisible until a mapping silently does not work in one of the two editors.

## Proposed Solution

Work through the remaining review findings in dependency order, replacing the ad-hoc
mapping layer with a **data-driven keymap spec** that serves both editors.

The central idea is a single table of keymap specs as the source of truth. A small
converter applies the specs to Neovim via `vim.keymap.set`, and can additionally emit the
equivalent Vim mapping commands. Emission is gated behind a `keymap_logging_enabled`
flag in the converter module, defaulting to `false`, so normal startup writes only
`Log.debug` lines while flipping the flag produces paste-ready vimscript in
`~/.tmp/nvim/nvim.log`.

The spec table also removes the `_G` bridge: every mapping that today reaches into
`_G` becomes a `<cmd>UserCommand<cr>` mapping backed by a real user command, which is
valid in both Vim and Neovim.

Sequencing is phased by risk so each phase is independently revertible:

- **Phase 1** — the keymap spec module and its emitter (the one new abstraction).
- **Phase 2** — small mechanical fixes and deletions that need no design decisions.
- **Phase 3** — collapse the three LSP modules into one table-driven module.
- **Phase 4** — migrate every call site onto the spec table; remove the `_G` bridge.
- **Phase 5** — `plugins.lua` determinism and the fzf plugin line.
- **Phase 6** — option changes and stylua tooling.

Explicitly out of scope for this plan (see Open Questions):

- The hand-rolled tabline in `settings.lua`. It stays as-is. The two genuine defects the
  review found in it (display-width math, hardcoded repo path in `mappings.lua:118`) are
  recorded as follow-ups rather than folded in.
- Parsing `config/vimrc` back into spec rows. The spec shape must settle first; the
  emitter is designed so this can be added later.

## Technical Details

### Verified current state

Confirmed still outstanding:

| Finding | Location |
| --- | --- |
| `_G` bridge (8 functions) | `globals.lua:28-36` |
| `_G.config_loaded` reload flag | `init.lua:3-11` |
| `M._create_commands` + deprecated `unpack` | `globals.lua:21-25` |
| Whole `map.lua` module | `map.lua:1-68` |
| LSP triplication, `omnifunc`, narrow `filetypes` | `lsp_clangd.lua`, `lsp_gopls.lua`, `lsp_jedi.lua` |
| `pairs()` plugin iteration, `initialized` mutation | `plugins.lua:240-248`, `265-269` |
| `['dir'] = '~/.fzf'` not tilde-expanded | `plugins.lua:94` |
| `io.output(file)` process-global stdout swap | `log.lua:26-29` |
| `path_sep`/`path_join` hardcoded `\\` on Windows | `util.lua:18-28` |
| `truncate_center` unused | `util.lua:192-219` |
| `print_current_filetype` reachable only via `_G` | `util.lua:85-87` |
| `is_int`/`is_string` reimplement `math.type`/`type` | `util.lua:53-59` |
| `is_buffer_modified` uses `vim.fn.getbufvar` | `util.lua:222-224` |
| `install_plugins` untested/unused | `vim_plug.lua:57-62` |
| `vim.cmd("luafile " .. config)` bypasses module cache | `util.lua:73` |
| `]]--` instead of `]]` | `lsp_clangd.lua:11` |
| `hidden = false`, `visualbell = true` | `settings.lua:14,17` |
| No `.stylua.toml`, no Lua formatting target | repo root, `Makefile` |

Confirmed already fixed, so excluded from the task list: the treesitter augroup wipe
(`treesitter.lua` now creates one group once), the `local init_result` leak
(`plugins.lua:265`), the missing `local` on `truncated_tabs` (`settings.lua:201`), the
unbounded `close_tabs_to_right` loop (`util.lua:121-138`), the `ShowSnippets` sink
ordering (`plugins.lua:50-56`), and the redundant `VimPlug.source()` call.

### Phase 1 — The keymap spec and emitter (`lua/dot/keymaps.lua`)

New module. It replaces `map.lua` and becomes the only place that knows how to install a
mapping or describe its Vim equivalent.

```lua
local M = {}

-- Flip to true and restart Neovim to write paste-ready vimscript for config/vimrc
-- into ~/.tmp/nvim/nvim.log via Log.info. Leave false in normal use.
M.keymap_logging_enabled = false

-- Spec row shape:
--   mode  (required) vim.keymap.set mode string: 'n', 'i', 'v', 'x', ''
--   key   (required) lhs
--   fn    (one of)    a Lua function, called directly by Neovim
--   rhs   (one of)    a string, passed through to vim.keymap.set
--   cmd   (optional)  a body for a ':' mapping, e.g. 'Files<cr>'. Neovim gets
--                     '<cmd>Files<cr>', and the emitter gets ':Files<cr>'.
--   vim   (optional)  overrides the derived Vim rhs; false means "no Vim
--                     equivalent" and the row is skipped when emitting
--   silent (optional) adds <silent>
--   buffer (optional) a bufnr for buffer-local mappings
--   ft    (optional)  a FileType pattern; expires the mapping per filetype
--   desc  (optional)  human-readable description, passed to vim.keymap.set
M.specs = {}

function M.add(rows) end      -- appends rows to M.specs
function M.init() end         -- applies M.specs via vim.keymap.set; logs when enabled
function M.to_vim_lines() end -- returns an array of vimscript lines (pure, testable)
function M.emit() end         -- writes to_vim_lines() through Log.info when enabled

return M
```

Applying a row:

```lua
local function apply(row)
    if row.ft then
        vim.api.nvim_create_autocmd('FileType', {
            pattern = row.ft,
            callback = function() apply(vim.tbl_extend('force', row, { ft = nil, buffer = 0 })) end,
        })
        return
    end

    local opts = { silent = row.silent, buffer = row.buffer, desc = row.desc }

    -- nvim_set_keymap semantics are inverted relative to vim.keymap.set:
    -- nvim_set_keymap defaults noremap=false (recursive), vim.keymap.set
    -- defaults remap=false (non-recursive). Everything in this config wants
    -- the non-recursive default, except the two recursive rows below which set
    -- opts.remap = true explicitly.
    if row.rhs and row.rhs:match('^<[Cc]md>') then
        opts.remap = true
    end

    vim.keymap.set(row.mode, row.key, row.fn or row.rhs or ('<cmd>' .. row.cmd), opts)
end
```

Deriving the Vim line:

| Neovim form | Emitted Vim line |
| --- | --- |
| `{ mode = 'n', key = k, cmd = 'wa<cr>', silent = true }` | `nnoremap <silent> k :wa<cr>` |
| `{ mode = 'v', key = 'Y', cmd = 'CopyCodeSnippet<cr>' }` | `vnoremap Y :CopyCodeSnippet<cr>` |
| `{ mode = 'x', key = k, cmd = 'normal<space>' }` | `xnoremap k :normal<space>` |
| `{ mode = '', key = '<Space>', rhs = '<Leader>', vim = 'map <Space> <Leader>' }` | `map <Space> <Leader>` |
| `{ mode = 'n', key = '1', rhs = '1gt' }` | `nnoremap 1 1gt` |
| `{ ft = 'python', mode = 'n', key = k, cmd = 'FormatPythonFile<cr>' }` | `autocmd FileType python nnoremap <buffer> k :FormatPythonFile<cr>` |
| `{ buffer = bufnr, mode = 'n', key = 'gd', cmd = 'lua vim.lsp.buf.definition()<cr>', vim = false }` | skipped |

Mode prefix table: `n` → `n`, `i` → `i`, `v` → `v`, `x` → `x`, `''` → `''` (bare `map`).

The `vim = false` escape hatch is what keeps Neovim-only mappings out of the output
instead of emitting something that would error in Vim.

`Buffer`-scoped rows whose only purpose is LSP are `vim = false`. Rows scoped with
`ft` are emitted as `<buffer>` inside a `FileType` autocmd, matching how `config/vimrc`
already writes `autocmd FileType c,cpp vnoremap <buffer> <Leader>q :ClangFormat<CR>`.

`M.init()` is called from `init.lua` at the same point `Mappings.init()` is called today.

### Phase 2 — Mechanical fixes and deletions

**`util.lua`**

- Delete `truncate_center` and its 28-line doc comment (unused).
- Delete `print_current_filetype` and its `_G` alias (no user command backs it).
- Delete `path_sep`; reimplement `path_join` over `vim.fs.joinpath`.
- Delete `str_join`; the two call sites (`path_join`, `get_file_and_line`) use
  `table.concat` / string concatenation directly.
- Delete `is_int`; `move_to_column` uses `math.type(column) == 'integer'` or an explicit
  `% 1 == 0` check.
- Delete `is_string`; callers use `type(x) == 'string'`.
- `directory_exists`/`file_exists` → a shared `local function stat(path)` returning
  `vim.uv.fs_stat(path)`, with `directory_exists` then checking `.type == 'directory'`.
  One syscall, no `vim.fn.isdirectory` or `io.open` handle juggling, and the boolean
  contract used by `vim_plug.is_installed` is preserved.
- `data_dir` is a one-line alias for `vim.fn.stdpath('data')`; keep it, since `init.lua`
  and `vim_plug.lua` both read better for it, but drop the alias in favour of a direct
  `vim.fn.stdpath('data')` call in `vim_plug.lua` and delete the wrapper.
- `is_buffer_modified` → `vim.bo[buffer_index].modified`, and delete the wrapper once
  `settings.lua:82` calls the option directly.

**`log.lua`** — replace the `io.open` + `io.output(file)` + `io.write` sequence with an
explicit file handle, so the process-global default output file is never touched:

```lua
local file = io.open(M.path, 'a')
if file == nil then return end
file:write(M._format(level, msg))
file:close()
```

**`vim_plug.lua`** — delete `install_plugins` (self-documented untested and unused), and
delete the module-level `path` field in favour of resolving the plug.vim path inline in
`is_installed`/`install`, now that nothing else overrides it.

**`lsp_clangd.lua`** — `]]--` → `]]`; delete the 15 commented-out mapping lines.

**`treesitter.lua`** — the `filetype_rules` table remains, but the `fallback` branch sets
`vim.sequential_glance_fallback`, which is not a Neovim variable. Reduce `filetype_rules`
to the ignore list it actually is (`fzf`, `netrw`) and drop the fallback branch and the
misleading comment that calls it "your old override".

### Phase 3 — One table-driven LSP module

Replace `lsp_clangd.lua`, `lsp_gopls.lua`, and `lsp_jedi.lua` with a single
`lua/dot/lsp.lua`:

```lua
local servers = {
    {
        name = 'clangd',
        executable = 'clangd',
        config = { flags = { debounce_text_changes = 150 } },
        keys = {
            { 'gD',    'declaration' },
            { 'gd',    'definition' },
            { 'K',     'hover' },
            { 'gi',    'implementation' },
            { 'gr',    'references' },
            { '<C-k>', 'signature_help' },
        },
    },
    {
        name = 'gopls',
        executable = 'gopls',
        config = { flags = { debounce_text_changes = 150 } },
        keys = {
            { '<leader>ld', 'definition' },
            { 'gr',         'references' },
            { 'gi',         'implementation' },
            { 'K',          'hover' },
            { '<C-k>',      'signature_help' },
        },
    },
    {
        name = 'jedi_language_server',
        executable = 'jedi-language-server',
        config = {},
        keys = {
            { 'gd',    'definition' },
            { 'gr',    'references' },
            { 'gi',    'implementation' },
            { 'K',     'hover' },
            { '<C-k>', 'signature_help' },
        },
    },
}
```

`M.configure()` registers **one** `LspAttach` autocmd in a `dot_lsp` augroup with
`clear = true`, looks up `client.name` in a name-indexed table built from `servers`, and
adds each mapping through the Phase 1 spec table with `cmd = 'lua vim.lsp.buf.<method>()<cr>'`,
`buffer = args.buf`, `silent = true`, `vim = false` (LSP does not exist in Vim). It then
calls `vim.lsp.config(name, config)` and `vim.lsp.enable(name)` for each server whose
executable is present, and skips servers whose executable is missing, matching today's
early-return behaviour.

Two deliberate changes:

- **Drop `vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'`.** On 0.12 `vim.lsp.start`
  already sets `omnifunc` via `set_defaults` when the server advertises a completion
  provider (`runtime/lua/vim/lsp.lua:1119-1122`). Verify by attaching clangd and checking
  `:setlocal omnifunc?` returns `v:lua.vim.lsp.omnifunc`; if it does not, keep the line.
- **Drop `filetypes = { 'c', 'cpp' }` from the clangd override.** lspconfig's own spec
  covers `cuda`, `objc`, and `objcpp` as well; the override silently narrows that. The
  jedi `filetypes = { 'python' }` override is also dropped, as the default spec already
  matches it.

`vim.lsp.log.set_level("off")` moves into this module, called once (today it is called
inside the clangd path only).

Keep the existing explanatory comment about not passing `on_attach` to `vim.lsp.config`,
since it documents a real constraint of lspconfig's default `on_attach`.

### Phase 4 — Migrate every call site, remove the `_G` bridge

`mappings.lua` becomes the spec table's data source. It groups rows into the same
private helpers (`_tabs`, `_buffers`, `_quickfix`, `_syntax`, `_resize`, `_misc`) but each
entry is a spec row rather than a `Map.nnoremap(...)` call. `plugins.lua` registers its
plugin-conditional mappings through the same table so there is one source of truth.

Convert the 15 mappings that currently use `:lua foo()` strings so they target user
commands instead. `globals.lua` gains these commands (names chosen to read well from both
editors) and loses its eight `_G` assignments:

| Today | After |
| --- | --- |
| `_G.copy_file_and_line` + `:lua copy_file_and_line()` | `:CopyFileAndLine`, mapped `<leader>y` |
| `_G.copy_code_snippet` + `:lua copy_code_snippet()` | `:CopyCodeSnippet`, mapped `Y` in visual mode |
| `_G.close_tabs_to_right` | already `:CloseTabsToRight` |
| `_G.move_to_column` | already `:MoveToColumn` |
| `_G.reload_config` | already `:ReloadConfig` |
| `_G.format_current_python_file` + `:lua format_current_python_file()` | `:FormatPythonFile`, mapped `<leader>q` for python |
| `_G.print_current_filetype` | deleted (Phase 2) |
| `_G.install_vim_plug` | `:InstallVimPlug`; update the notification at `plugins.lua:234` |

`ShowSnippets` becomes `:ShowSnippets`, defined in the fzf plugin's `configure` block and
mapped with `cmd = 'ShowSnippets<cr>'`, replacing the raw `nvim_set_keymap` call at
`plugins.lua:107` and the "copy/pasted from ChatGPT" TODO above it.

The two remaining non-spec keymaps are legitimately special and stay as direct
`vim.keymap.set` calls with a comment saying why:

- copilot's `<C-J>` needs `expr = true` and `replace_keycodes = false`, which the spec
  table does not model. Add `expr`/`replace_keycodes` fields only if a second call site
  appears.
- Nothing else — the `ShowSnippets` and `<leader>fs` case is covered above.

`globals.lua` cleanup: `M._create_commands` (a layer over `nvim_create_user_command`
used once) is inlined into a plain list of `nvim_create_user_command` calls, removing the
deprecated `unpack`. `M._reload_snippets` stays as the callback for `:ReloadSnippets`.

`init.lua`: replace the `_G.config_loaded` reload flag with a module-local table (for
example `require('dot')._loaded`), or reduce `reload_config` to a documented
"restart Neovim to pick up changes" if the module purge cannot be made reliable. Decide
during implementation by testing `:ReloadConfig` with the flag removed; if maps stack up
on reload, keep the purge but hold the flag in a module instead of `_G`.

**Documentation of the Leader preference.** `Map.map('<Space>', '<Leader>')` becomes the
spec row `{ mode = '', key = '<Space>', rhs = '<Leader>', vim = 'map <Space> <Leader>' }`.
The existing comment in `mappings.lua:106-108` explaining why `mapleader` is not set to
space moves to this row.

### Phase 5 — `plugins.lua` determinism and the fzf line

- Convert `plugins` from a string-keyed table to an ordered array of specs. `M.init` and
  `M._configure_plugin` iterate with `ipairs`, making load order explicit and
  deterministic. The first element gets a comment stating that order is significant.
- Keep the `is_enabled` → `init` → `initialized` → `configure` lifecycle, since it maps
  onto vim-plug's `plug#begin`/`plug#end` boundary. Remove the `Notifications.add`
  warning for a plugin with no `init` function — with an ordered array, a spec with no
  `init` is a mistake worth an error, not a notification, and every current spec has one.
- `plugin.initialized = true` continues to mutate the spec element. Replace it with a
  local `initialized` set (`initialized[plugin_name] = true`) so the static config table
  is not mutated.
- Change `Plug('junegunn/fzf', { ['dir'] = '~/.fzf', ['do'] = './install --bin' })` to
  `Plug('junegunn/fzf')`. fzf is installed separately and Neovim must not try to build it;
  this also removes the non-tilde-expanded `dir` option entirely.
- Fix the `end,        configure = function()` formatting casualty on the `lsp_config`
  spec (Phase 6's stylua run also covers this, but Phase 5 rewrites the file).
- `lsp_config.configure` requires the three `dot.lsp_*` modules; update it to require the
  single `dot.lsp` module from Phase 3.

### Phase 6 — Options and formatting

`settings.lua`:

- `vim.opt.hidden = true`. `config/vimrc`'s `set nohidden` becomes `set hidden` so the two
  editors stay in sync. The comment at `util.lua:118-120` that cites E37 on a modified
  buffer with `'hidden'` off as the expected `close_tabs_to_right` failure mode must be
  reworded, since that failure mode is now much harder to trigger. Keep the guard: it is
  still correct defensive code.
- Drop `vim.opt.visualbell = true` and replace it with `vim.opt.belloff = 'all'`, which is
  what "No sounds" actually means in a terminal.
- Leave `vim.opt.autowrite = true` alone; it is mirrored by `set autowrite` in
  `config/vimrc` and is a deliberate preference.
- `vim.opt` vs `vim.o`: `vim.o.columns` (a scalar read) is already correct; the remaining
  set of scalar options use `vim.opt`, which is also correct. No change needed beyond
  confirming `vim.o.tabline` and `vim.o.statusline` stay `vim.o` (they are string sets,
  and `vim.opt` would work but `vim.o` is the documented form for a plain string).

Formatting tooling:

- Add `.stylua.toml` at the repo root with `indent_type = "Spaces"`, `indent_width = 4`,
  `column_width = 100`, `quote_style = "AutoPreferSingle"` for consistency with the
  existing single-quoted strings.
- Add a `fmt-lua` target to `Makefile` running
  `stylua --config-path .stylua.toml config/nvim`, plus a `--check` variant, and add
  `fmt-lua` to the `help` text.
- Add a `StyluaProvisioner` (`src/dot/lib/provision/provisioner_stylua.py`) registered as
  the `stylua` component after `rust` in `system_provisioner.py`, following the
  `provisioner_ripgrep.py` version-tracked pattern: fetch the latest
  `JohnnyMorganz/Stylua` release, download `stylua-linux-x86_64.zip` from
  `Github.download_release_artifact`, extract with `Archive`, and install the binary.
  Gate the whole component on non-Windows, matching how `ripgrep` installs a `.deb`.
- Run `stylua` once and commit the normalized output as its own commit so the mechanical
  reflow does not obscure the functional diffs.

## Open Questions / Notable Risks

- **The tabline stays untouched.** The tabline is out of scope, including the two real
  defects the review found: length math in `_format_tabline_basic_truncation` uses `#`
  (bytes) rather than `vim.fn.strdisplaywidth` (cells), so multi-byte titles mis-measure,
  and `mappings.lua:118` hardcodes `~/dot/config/nvim/init.lua`, which `Util.config_path()`
  would resolve correctly. Both are recorded here as follow-ups. Phase 6 changes
  `hidden`, which makes the tabline's `is_modified` marker less frequently visible but
  does not affect its correctness.
- **`vim = false` rows are invisible to the Vim emitter by design.** LSP and telescope
  mappings will never appear in the generated vimscript. This is intended, but it means
  the emitted file is not a full inventory of your keymaps. Confirm this is the desired
  behaviour after the first emission.
- **The `_G.config_loaded` purge may be load-bearing.** If Neovim's module cache must be
  purged for `:ReloadConfig` to pick up changes without stacking autocmds, a module-local
  flag will not survive `luafile`. The fallback is to keep the purge and accept the
  module-local flag only if testing shows reload still works; otherwise `reload_config`
  becomes a documented "restart Neovim".
- **Dropping the clangd `filetypes` override widens the server to `cuda`/`objc`/`objcpp`.**
  If clangd on this machine produces noisy diagnostics for files that previously fell
  through, restore `filetypes = { 'c', 'cpp' }` in the clangd entry's `config`.
- **`vim.fs.joinpath` is 0.10+.** The config targets 0.12.5, so this is safe, but note it
  if the config is ever expected to run on older Neovim.
- **Reverse conversion (vim-to-spec) is deliberately deferred.** The emitter format must
  be stable before a parser is written against it.

## Task Breakdown

1. **Create `lua/dot/keymaps.lua`.** Add the `M.specs` table, `M.add`, `M.init`,
   `M.to_vim_lines`, `M.emit`, and the `keymap_logging_enabled` flag (default `false`).
   Implement `apply(row)` with the `ft` → `FileType` autocmd expansion, the `buffer`
   option, and the `remap` handling for `<cmd>` strings. Implement `to_vim_lines()` with
   the mode-prefix table and the `vim = false` skip.
2. **Verify the emitter in isolation.** Add a scratch spec covering every row shape
   (plain, silent, buffer, filetype, `cmd`, `rhs`, recursive, `vim = false`), set
   `keymap_logging_enabled = true`, start Neovim, and confirm the lines in
   `~/.tmp/nvim/nvim.log` are valid vimscript by sourcing the emitted block in Vim. Fix
   the emitter before proceeding.
3. **Fix `util.lua`.** Delete `truncate_center`, `print_current_filetype`, `path_sep`,
   `str_join`, `is_int`, `is_string`; reimplement `path_join` over `vim.fs.joinpath`;
   reimplement `directory_exists`/`file_exists` over `vim.uv.fs_stat`; inline
   `is_buffer_modified` at its one call site in `settings.lua`; drop `data_dir` and call
   `vim.fn.stdpath('data')` directly in `vim_plug.lua`.
4. **Fix `log.lua`.** Replace `io.output(file)`/`io.write` with an explicit `file:write`
   and handle a failed `io.open`. Confirm existing log output is unchanged.
5. **Fix `vim_plug.lua`.** Delete `install_plugins` and the module-level `path` field;
   resolve the plug.vim path inline.
6. **Tidy `treesitter.lua`.** Reduce `filetype_rules` to the ignore list, delete the
   `vim.sequential_glance_fallback` branch and its comment, and remove the `]]--`-adjacent
   stale comments in the file.
7. **Create `lua/dot/lsp.lua`.** Implement the `servers` table, the single `dot_lsp`
   `LspAttach` autocmd, per-server `vim.lsp.config`/`vim.lsp.enable` with executable
   gating, and `vim.lsp.log.set_level("off")`. Register mappings through the Phase 1 spec
   table with `vim = false`.
8. **Verify `omnifunc`.** Attach clangd to a C file with the `omnifunc` line removed and
   confirm `:setlocal omnifunc?` still reports `v:lua.vim.lsp.omnifunc`. Restore the line
   in the shared module if it does not.
9. **Delete `lsp_clangd.lua`, `lsp_gopls.lua`, and `lsp_jedi.lua`.** Point
   `plugins.lua`'s `lsp_config.configure` at `dot.lsp`.
10. **Convert `mappings.lua` to spec rows.** Rewrite each helper group as `M.specs` rows,
    preserving every existing lhs/rhs pair exactly, and set `vim = false` on nothing that
    has a legitimate Vim equivalent. Move the Leader comment onto the `<Space>` row.
11. **Add the user commands to `globals.lua`.** Add `CopyFileAndLine`, `CopyCodeSnippet`,
    `FormatPythonFile`, and `InstallVimPlug`; inline `_create_commands`; delete all eight
    `_G` assignments; update the `plugins.lua:234` notification to name `:InstallVimPlug`.
12. **Migrate plugin-conditional mappings.** In `plugins.lua`, replace every `Map.*` call
    with a `Keymaps.add` row; add `:ShowSnippets` in the fzf `configure` block and map
    `<leader>fs` to it; keep the copilot `<C-J>` mapping as a direct `vim.keymap.set`
    with an expanded comment explaining the `expr`/`replace_keycodes` exemption.
13. **Delete `lua/dot/map.lua`** once no call sites remain, and update `init.lua` to
    require and init `dot.keymaps` in place of `dot.mappings` (or keep `mappings.lua` as
    the spec data module and require both).
14. **Remove the `_G.config_loaded` flag.** Move the reload state into a module; test
    `:ReloadConfig` for stacked autocmds and duplicated mappings. If reload regresses,
    replace the body of `reload_config` with a "restart Neovim" message and delete the
    purge loop.
15. **Generate and reconcile the Vim mappings.** Set `keymap_logging_enabled = true`,
    restart Neovim, and diff the emitted block against the mapping section of
    `config/vimrc`. Apply the missing mappings from the drift list (`<leader><tab>n`,
    `<leader><tab>p`, `<leader><tab>q`, the `<leader>be`/`<leader>x` target changes, the
    telescope mappings that make sense in Vim) and record the intentional divergences as
    comments in
    `config/vimrc`. Set the flag back to `false`.
16. **Convert `plugins.lua` to an ordered array.** Change `plugins` to an array loaded
    with `ipairs`, replace `plugin.initialized` with a local `initialized` set, drop the
    no-`init` notification, simplify the fzf `Plug` line to `Plug('junegunn/fzf')`, and
    fix the `lsp_config` formatting casualty.
17. **Apply the option changes.** Set `vim.opt.hidden = true` and change `config/vimrc`'s
    `set nohidden` to `set hidden`; replace `visualbell` with `belloff = 'all'`; reword
    the `close_tabs_to_right` comment that cites E37.
18. **Add `.stylua.toml` and the `fmt-lua` target.** Add the config file, add the Makefile
    targets, and add `fmt-lua` to the `help` text.
19. **Add the `stylua` provisioner.** Create
    `src/dot/lib/provision/provisioner_stylua.py` following `provisioner_ripgrep.py`,
    register it after `rust` in `_COMPONENT_PROVISIONERS`, and provision it on this
    machine.
20. **Run stylua and commit separately.** Run `make fmt-lua`, verify no semantic changes
    by reading the diff, and commit the reflow on its own.
21. **Update `improvements.md`.** Mark each completed finding, and add the two tabline
    defects and the reverse-conversion idea to a clearly labelled "deferred" section so
    the file remains an accurate record.
22. **Documentation review.** Review `README.md`, `AGENTS.md`, `CLAUDE.md`,
    `.github/copilot-instructions.md`, and the files in `.github/instructions/` for content
    made inaccurate or incomplete by these changes, and update as needed. In particular,
    `AGENTS.md` describes the `dot provision` component list and the `Makefile` targets;
    add `stylua` to the former and `fmt-lua` to the latter. Note that the plan document
    format's standard list names `docs/feature-dev-pipeline.md` and
    `.github/instructions/test-conventions.instructions.md`, neither of which exists in
    this repository — review the files that do exist instead.
