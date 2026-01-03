Context Files:

File `./config/nvim/init.lua`:
```
local vim = vim

if _G.config_loaded == true then
    for name, _ in pairs(package.loaded) do
        if name:match('^dot%..*$') then
            package.loaded[name] = nil
        end
    end
end

_G.config_loaded = true

local Globals       = require('dot.globals')
local Log           = require('dot.log')
local Mappings      = require('dot.mappings')
local Notifications = require('dot.notifications')
local Plugins       = require('dot.plugins')
local Settings      = require('dot.settings')
local Theme         = require('dot.theme')
local Util          = require('dot.util')

local tmp_dir = Util.tmp_dir()

if not Util.directory_exists(tmp_dir) then
    vim.fn.mkdir(tmp_dir, "p", "0775")
end

Log.init(Log.levels.info, Util.path_join(tmp_dir, "nvim.log"))
Log.debug('loading init.lua')

Settings.init()
Plugins.init()
Mappings.init()
Globals.init()
Theme.init()

if Util.is_wsl() then
    local Wsl = require('dot.wsl')
    Wsl.init()
end

if Notifications.any() then
    Notifications.display()
    vim.o.statusline = "Configuration errors occurred; see quickfix list for details"
end

Log.debug('finished loading init.lua')
```

File `./config/nvim/lua/dot/log.lua`:
```
local vim = vim

local M = {
    path = nil,
    level = nil,
    levels = {
        off   = { display = "[off]  ", value = 0, vim_level = vim.log.levels.OFF   },
        trace = { display = "[trace]", value = 1, vim_level = vim.log.levels.TRACE },
        debug = { display = "[debug]", value = 2, vim_level = vim.log.levels.DEBUG },
        info  = { display = "[info] ", value = 3, vim_level = vim.log.levels.INFO  },
        warn  = { display = "[warn] ", value = 4, vim_level = vim.log.levels.WARN  },
        error = { display = "[error]", value = 5, vim_level = vim.log.levels.ERROR },
    }
}

function M._format(level, msg)
    -- TODO: Add a timestamp
    return level.display .. " " .. msg .. "\n"
end

function M._log(level, msg)
    if M.path == nil or M.level == nil or level.value < M.level.value then
        return
    end

    local file = io.open(M.path, "a")
    io.output(file)
    io.write(M._format(level, msg))
    io.close(file)
end

function M.trace(msg) M._log(M.levels.trace, msg) end
function M.debug(msg) M._log(M.levels.debug, msg) end
function M.info(msg)  M._log(M.levels.info,  msg) end
function M.warn(msg)  M._log(M.levels.warn,  msg) end
function M.error(msg) M._log(M.levels.error, msg) end

function M.init(level, path)
    M.level = level
    M.path = path
end

return M
```

File `./config/nvim/lua/dot/plugins.lua`:
```
local vim = vim
local Plug = vim.fn["plug#"]

local Log           = require('dot.log')
local Map           = require('dot.map')
local Notifications = require('dot.notifications')
local Util          = require('dot.util')
local VimPlug       = require('dot.vim_plug')

-- TODO: Copy/pasted from ChatGPT, find the right place for this and read
-- through it
-- Function to list snippets and allow FZF selection
function ShowSnippets()
  local filetype = vim.bo.filetype  -- Get the current filetype
  local snippets = vim.fn["UltiSnips#SnippetsInCurrentScope"](1)  -- Get available snippets

  -- If no snippets available, notify the user
  if vim.tbl_isempty(snippets) then
    print("No snippets available for this filetype.")
    return
  end

  -- Prepare snippets for FZF display
  local fzf_snippets = {}
  for trigger, info in pairs(snippets) do
    local description = info.description or ""
    table.insert(fzf_snippets, trigger .. " - " .. description)
  end

  -- Use FZF to select a snippet
  vim.fn["fzf#run"]({
    source = fzf_snippets,
    sink = function(choice)
      if choice then
        local snippet_trigger = choice:match("^(%S+)")
        vim.cmd("call UltiSnips#ExpandSnippetOrJump()")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(snippet_trigger, true, false, true), 'm', true)
      end
    end
  })
end

local M = {}

local plugins = {
    copilot = {
        is_enabled = function()
            return os.getenv("NVIM_COPILOT_ENABLED") == "1"
        end,
        init = function()
            Plug('github/copilot.vim')
        end,
        configure = function()
            -- Don't use tab to accept Copilot suggestions which conflicts with
            -- snippets. Not using my Map.imap() function here because it
            -- doesn't support passing through the `replace_keycodes` and `expr`
            -- options. (TODO: Add that support)
            -- I'm not sure why those are necessary but this is copied from:
            -- https://github.com/github/copilot.vim/blob/53d3091be388ff1edacdb84421ccfa19a446a84d/doc/copilot.txt#L119-L132
            vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
                expr = true,
                replace_keycodes = false
            })
            vim.g.copilot_no_tab_map = true

            vim.g.copilot_filetypes = {
                -- Don't enable copilot in markdown files; it generally makes
                -- bad predictions
                markdown = false
            }
        end
    },

    fzf = {
        init = function()
            Plug('junegunn/fzf', { ['dir'] = '~/.fzf', ['do'] = './install --bin' })
            Plug('junegunn/fzf.vim')
        end,
        configure = function()
            -- We should remove this eventually in favor of the below
            Map.nnoremap('<Leader>o', ':Files<CR>')

            Map.nnoremap('<leader>ft', ':Tags<cr>')
            Map.nnoremap('<leader>fo', ':Files<cr>')

            -- TODO: Copy/pasted from ChatGPT, clean up to use the Map module
            -- like above
            -- Map the function to a keybinding (e.g., <leader>s)
            vim.api.nvim_set_keymap("n", "<leader>fs", "<cmd>lua ShowSnippets()<CR>", { noremap = true, silent = true })
        end
    },

    telescope = {
        init = function()
            Plug('nvim-telescope/telescope.nvim')
        end,
        configure = function()
            Map.nnoremap('<leader>tf', ':Telescope find_files<cr>')
            Map.nnoremap('<leader>tt', ':Telescope tags<cr>')
            Map.nnoremap('<leader>ts', ':Telescope lsp_dynamic_workspace_symbols<cr>')
            Map.nnoremap('<leader>tg', ':Telescope live_grep<cr>')
            Map.nnoremap('<leader>tb', ':Telescope buffers<cr>')
            Map.nnoremap('<leader>th', ':Telescope help_tags<cr>')
        end
    },

    nvim_treesitter = {
        init = function()
            -- Sometimes the automatic :TSUpdate won't run successfully and then it
            -- won't rerun. If cryptic treesitter errors show up after running
            -- :PlugUpdate, try running :TSUpdate manually
            Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate'})
        end,
        configure = function()
            local Treesitter = require('dot.treesitter')
            Treesitter.configure()
        end
    },

    ultisnips = {
        init = function()
            Plug('SirVer/ultisnips')
            Plug('honza/vim-snippets')
        end,
        configure = function()
            vim.g.UltiSnipsExpandTrigger = "<tab>"
            vim.g.UltiSnipsJumpForwardTrigger = "<c-j>"
            vim.g.UltiSnipsJumpBackwardTrigger = "<c-k>"

            Map.nnoremaps('<leader>ue', ':UltiSnipsEdit<CR>')

        end
    },

    nvim_markdown = {
        init = function()
            Plug('ixru/nvim-markdown')
        end,
        configure = function()
            vim.g.vim_markdown_frontmatter = 1

            -- This is <tab> by default which conflicts with UltiSnips
            -- TODO: Should we only do this in markdown files?
            Map.imap('<Plug>', '<Plug>Markdown_Jump')
        end
    },

    clang_format = {
        init = function()
            Plug('rhysd/vim-clang-format')
        end,
        configure = function()
            -- Format the current C/C++ file with clang-format (Uses vim-clang-format plugin)
            vim.g['clang_format#detect_style_file'] = 1
            Map.ft_vnoremap('c,cpp', '<Leader>q', ':ClangFormat<CR>')
        end
    },

    lsp_config = {
        init = function()
            Plug('neovim/nvim-lspconfig')
        end,
        configure = function()
            local LspClangd = require('dot.lsp_clangd')
            local LspGopls = require('dot.lsp_gopls')
            local LspJedi = require('dot.lsp_jedi')

            LspClangd.configure()
            LspGopls.configure()
            LspJedi.configure()

            Map.nnoremap('<leader>ls', ':LspStop<cr>')
        end
    },

    other = {
        init = function()
            -- Colorschemes
            Plug('chriskempson/base16-vim')

            Plug('rodjek/vim-puppet')
            Plug('fatih/vim-go')
            Plug('OrangeT/vim-csharp')
            Plug('mattn/emmet-vim')
            Plug('tpope/vim-vinegar')
            Plug('nvie/vim-flake8')
            Plug('tikhomirov/vim-glsl')
            Plug('martinda/Jenkinsfile-vim-syntax')
            Plug('aklt/plantuml-syntax')
            Plug('elubow/cql-vim')
            Plug('tpope/vim-fugitive')
            Plug('igankevich/mesonic')
            Plug('hrsh7th/nvim-cmp')
            Plug('nvim-lua/popup.nvim')
            Plug('nvim-lua/plenary.nvim')
            Plug('glepnir/lspsaga.nvim')
            Plug('hoob3rt/lualine.nvim')
        end
    },
}

function M.init()
    if not VimPlug.is_installed() then
        Notifications.add("vim-plug is not installed; install it via `:lua install_vim_plug()`")
        return
    end

    -- Ever since switching from init.vim to init.lua, it doesn't seem like
    -- Neovim autoloads the plug.vim file anymore. I'm not sure why and don't
    -- have time right now to dig into it so just manually source it for now.
    VimPlug.source()

    vim.call('plug#begin')

    for plugin_name, plugin in pairs(plugins) do
        M._init_plugin(plugin_name, plugin)
    end

    vim.call('plug#end')

    for plugin_name, plugin in pairs(plugins) do
        M._configure_plugin(plugin_name, plugin)
    end
end

function M._init_plugin(plugin_name, plugin)
    if plugin.is_enabled ~= nil and not plugin.is_enabled() then
        Log.debug('skip initializing ' .. plugin_name .. ' plugin because it is disabled')
        return
    end

    Log.debug('initializing ' .. plugin_name .. ' plugin')

    if plugin.init == nil then
        Log.warn('plugin ' .. plugin_name .. ' has no init function')
        Notifications.add('plugin ' .. plugin_name .. ' has no init function')
        return
    end

    init_result = plugin.init()
    if init_result == nil or init_result == true then
        plugin.initialized = true
    end
end

function M._configure_plugin(plugin_name, plugin)
    if plugin.initialized == nil or not plugin.initialized then
        Log.debug('skip configuring ' .. plugin_name .. ' plugin because it is not initialized')
        return
    end

    Log.debug('configuring ' .. plugin_name .. ' plugin')

    if plugin.configure ~= nil then
        plugin.configure()
    end
end

return M
```

File `./config/nvim/lua/dot/theme.lua`:
```
local Log           = require('dot.log')
local Notifications = require('dot.notifications')
local Util          = require('dot.util')

local M = {}

function M._color_scheme()
    -- Start flavours - nvim
    local color_scheme = 'base16-outrun-dark'
    -- End flavours - nvim

    vim.g.base16colorspace = 256

    local status, _ = pcall(vim.cmd, 'colorscheme ' .. color_scheme)
    if not status then
        Notifications.add('Colorscheme ' .. color_scheme .. ' is not installed; install it via `:PlugInstall`')
    end
end

function M._background()
    if Util.is_windows() then
        vim.opt.background = 'dark'
    else
        -- On Non-Windows operating systems, use the host window's background.
        -- This allows for transparency if the terminal has that configured.
        vim.api.nvim_set_hl(0, 'Normal', {
            bg = 'NONE',
            ctermbg = 'NONE'
        })
    end
end

function M.init()
    M._color_scheme()
    M._background()
end

return M
```

File `./config/nvim/lua/dot/map.lua`:
```
-- The functions in this file aren't really necessary but they are just
-- convenient wrappers to make converting my existing vimscript configuration
-- files over to lua a little less painful and also make my mappings more terse.
-- The lua api is nicer but it's also rather verbose.

local vim = vim

local Log = require('dot.log')

local opts = {
    none = { noremap = false, silent = false },
    n    = { noremap = true,  silent = false },
    s    = { noremap = false, silent = true  },
    ns   = { noremap = true,  silent = true  }
}

local M = {}

function M._map(buffer, mode, lhs, rhs, opts)
    if buffer == nil then
        Log.debug("Mapping '" .. lhs .. "' to '" .. rhs .. "' in " .. mode .. " mode in all buffers")
        vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
    else
        Log.debug("Mapping '" .. lhs .. "' to '" .. rhs .. "' in " .. mode .. " mode in buffer " .. buffer)
        vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
    end
end

function M._mapft(filetype, lhs, rhs, mapfunc)
    vim.api.nvim_create_autocmd("FileType", {
        pattern = filetype,
        callback = function()
            mapfunc(0, lhs, rhs)
        end
    })
end

-- These functions are convenience wrappers that mirror the vim map commands.
-- For example, the `nnoremap` function is equivalent to running:
-- :nnoremap ... ...
--
-- The variants with an `s` appended are equivalent to adding a `<silent>` and
-- the variants with a `b` appended will only be mapped in the specified buffer.
--
-- The list is not exhaustive; I only added the ones that I actually use in my
-- configs.
function M.map           (lhs, rhs) M._map(nil, '',  lhs, rhs, opts.none) end
function M.imap          (lhs, rhs) M._map(nil, 'i', lhs, rhs, opts.none) end
function M.nnoremap      (lhs, rhs) M._map(nil, 'n', lhs, rhs, opts.n)    end
function M.nnoremaps     (lhs, rhs) M._map(nil, 'n', lhs, rhs, opts.ns)   end
function M.vnoremap      (lhs, rhs) M._map(nil, 'v', lhs, rhs, opts.n)    end
function M.vnoremaps     (lhs, rhs) M._map(nil, 'v', lhs, rhs, opts.ns)   end
function M.xnoremap      (lhs, rhs) M._map(nil, 'x', lhs, rhs, opts.n)    end
function M.xnoremaps     (lhs, rhs) M._map(nil, 'x', lhs, rhs, opts.ns)   end
function M.nnoremapb  (b, lhs, rhs) M._map(b,   'n', lhs, rhs, opts.n)    end
function M.nnoremapbs (b, lhs, rhs) M._map(b,   'n', lhs, rhs, opts.ns)   end
function M.vnoremapb  (b, lhs, rhs) M._map(b,   'v', lhs, rhs, opts.n)    end
function M.vnoremapbs (b, lhs, rhs) M._map(b,   'v', lhs, rhs, opts.ns)   end
function M.xnoremapb  (b, lhs, rhs) M._map(b,   'x', lhs, rhs, opts.n)    end
function M.xnoremapbs (b, lhs, rhs) M._map(b,   'x', lhs, rhs, opts.ns)   end

-- These functions are convenience wrappers for setting up filetype-specific
-- mappings. For example, the `ft_nnoremape` function is equivalent to running:
-- :autocmd FileType ... nnoremap ... ...
function M.ft_nnoremap(ft, lhs, rhs) M._mapft(ft, lhs, rhs, M.nnoremapb) end
function M.ft_vnoremap(ft, lhs, rhs) M._mapft(ft, lhs, rhs, M.vnoremapb) end

return M
```

File `./config/nvim/lua/dot/settings.lua`:
```
local Util = require('dot.util')
local Log = require('dot.log')

local M = {}

-- Base settings
function M._base()
    vim.opt.number = true                             -- Show line numbers
    vim.opt.backspace = { "indent", "eol", "start" }  -- Make backspace behave as expected in insert mode
    vim.opt.history = 1000                            -- Increase :cmdline history
    vim.opt.showcmd = true                            -- Show incomplete commands
    vim.opt.showmode = true                           -- Show current mode
    vim.opt.guicursor = 'a:blinkon0'                  -- Disable cursor blink
    vim.opt.visualbell = true                         -- No sounds
    vim.opt.autoread = true                           -- Reload files changed outside vim
    vim.opt.autowrite = true                          -- Write the file on :make
    vim.opt.hidden = false                            -- Hide buffer instead of closing it
    vim.opt.splitright = true                         -- When splitting vertically, the new pane should be on the right
    vim.opt.splitbelow = true                         -- When splitting horizontally, the new pane should be on the bottom
    vim.opt.ruler = true                              -- Show the line & column number at cursor
    vim.opt.clipboard = "unnamed,unnamedplus"         -- Use system clipboard if possible
    vim.opt.cursorline = true                         -- Add a visual indicator to the line the cursor is on
    vim.opt.joinspaces = false                        -- Don't insert an extra space after periods when joining lines

    -- Use global status line
    vim.opt.laststatus = 3
end

-- Indentation settings
function M._indentation()
    vim.opt.autoindent  = true
    vim.opt.smartindent = true
    vim.opt.smarttab    = true
    vim.opt.shiftwidth  = 4
    vim.opt.softtabstop = 4
    vim.opt.tabstop     = 4
    vim.opt.expandtab   = true

    -- Disable smart indent in markdown files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            vim.opt_local.smartindent = false
        end
    })
end

function M._directories()
    -- Add a double slash on the path which instructs Neovim to create a unique
    -- directory for each editing session
    -- TODO: Should this be \\ on windows?
    local dir = Util.tmp_dir() .. "//"

    Log.debug('Setting backup dir to ' .. dir)

    -- Backup and swap directories; the double slashes are important here
    vim.opt.backupdir = { dir, "." }
    vim.opt.directory = { dir, "." }
end

function M._get_tab_info(i)
    -- Check whether or not the tab is selected
    local is_selected = false
    if i == vim.fn.tabpagenr() then
        is_selected = true
    end

    local buflist = vim.fn.tabpagebuflist(i)
    local winnr = vim.fn.tabpagewinnr(i)

    -- The title is the name of the file currently open in the buffer focused
    -- within the tab. If it doesn't have one because it's an unsaved buffer,
    -- fall back to UNSAVED
    local title = vim.fn.fnamemodify(vim.fn.bufname(buflist[winnr]), ":t")
    if #title == 0 then
        title = "UNSAVED"
    end

    -- Check if any buffers open in the tab are modified and need to be save
    local is_modified = false
    for _, i in ipairs(buflist) do
        if Util.is_buffer_modified(i) then
            Log.debug("buffer " .. i .. " is modified")
            is_modified = true
            break
        end
    end

    return {
        title = title,
        index = i,
        is_modified = is_modified,
        is_selected = is_selected
    }
end

function M._format_tabline_tab(tab)
    local s = ""

    -- Format the modified indicator
    s = s .. (tab["is_modified"] and "+" or " ")

    -- Format the tab index
    s = s .. "[" .. tab["index"] .. "] "

    -- Format the tab title
    s = s .. tab["title"]

    return s
end

function M._format_tabline_no_truncation(tabs)
    local s = ""
    for i, tab in pairs(tabs) do
        -- Separate tabs with a space
        if i > 1 then
            s = s .. " "
        end
        -- Set the tab metadata
        s = s .. (tab["is_selected"] and "%#TabLineSel#" or "%#TabLine#")
        s = s .. "%" .. tab["index"] .. "T"

        s = s .. M._format_tabline_tab(tab)
    end
    return s .. '%#TabLineFill#%T'
end

-- The "Basic" truncation strategy is to hide all of the tabs that don't fit on
-- the tabline and put an indicator on the right of how many more tabs there
-- are. I Personallly like this better than squishing each tab down. I'd rather
-- the first N tabs be readable and just hide the ones that don't fit than make
-- them all less readable.
function M._format_tabline_basic_truncation(tabs, truncation)
    -- TODO: We could merge this loop with the one below and do this in one
    -- pass but I'm too lazy right now
    local tab_contents = {}
    for i, tab in pairs(tabs) do
        local meta = (tab["is_selected"] and "%#TabLineSel#" or "%#TabLine#")
        meta = meta .. "%" .. tab["index"] .. "T"

        local label = M._format_tabline_tab(tab)

        tab_contents[i] = {
            meta = meta,
            label = label
        }
    end

    local suffix_base_len = #" ... (x more)"
    local current_length = 0
    local truncate_index = 0
    for i, tab_content in pairs(tab_contents) do
        -- First, check if we can even fit the truncation suffix. It could be
        -- longer than the tab label if the file in the tab has a very short
        -- name. If this won't fit, then we actually need to start truncating
        -- at the previous tab
        local remaining_tabs = (#tabs - i) + 1
        local suffix_len = suffix_base_len + math.floor(remaining_tabs / 10)
        if (current_length + suffix_len) > truncation["max_length"] then
            truncate_index = math.max(0, i - 1)
            break
        end

        -- Separate tabs with a space
        local separator = ""
        if i > 1 then
            separator = " "
        end

        local tab_len = #tab_content["label"] + #separator

        -- If appending this label would exceed the max length, start
        -- truncating at this tab
        if (current_length + tab_len) > truncation["max_length"] then
            truncate_index = i
            break
        end

        current_length = current_length + tab_len
    end

    -- Now that we know where to start truncating, format the tabline
    local s = ""
    for i, tab_content in pairs(tab_contents) do
        if i >= truncate_index then
            break
        end
        if i > 1 then
            s = s .. " "
        end
        s = s .. tab_content["meta"] .. tab_content["label"]
    end

    -- Align the truncation suffix to the right
    s = s .. "%="

    -- Fill any extra space and disassociate the following text from the last tab
    s = s .. "%#TabLineFill#%T"

    -- Append the truncation suffix
    local truncated_tabs = (#tabs - truncate_index) + 1
    s = s .. "... (" .. tostring(truncated_tabs) .. " more)"

    return s
end

function M._format_tabline(tabs, truncation)
    if truncation["strategy"] == "Basic" then
        return M._format_tabline_basic_truncation(tabs, truncation)
    else
        return M._format_tabline_no_truncation(tabs)
    end
end

-- Tabline generation is done in two steps. The first step collects all of the
-- tab information and the second step formats the tabline. The reason is that
-- we need to be able to check the total length and truncate appropriately.
-- That's harder to do when the string contains characters that are actually
-- printed, like the `%#TabLine#` tokens. So instead, we need to gather all of
-- the desired tab labels, sum their lengths, choose a truncation strategy, and
-- then format everything using that strategy.
function M._generate_tabline()
    -- Get all of the tab information
    local tabs = {}
    for i = 1, vim.fn.tabpagenr('$') do
        tabs[i] = M._get_tab_info(i)
    end

    -- The length of the tab label prefix (I.E. "+[1] "), which can vary if the
    -- tab index is multiple digits. Ignoring the case of >100 tabs; I never
    -- use that many and there would be no good way to format that anyways
    local prefix_length = #tabs >= 10 and 6 or 5

    local total_length = 0
    for _, tab in ipairs(tabs) do
        local title_len = #tab["title"]
        local tab_len = title_len + prefix_length
        total_length = total_length + tab_len
    end

    -- We separate tabs with a space so account for that as well
    total_length = total_length + #tabs - 1

    local truncation = {
        strategy = "None",
        total_length = total_length,
        max_length = vim.o.columns,
        amount = 0,
        amount_per_tab = 0,
    }

    -- Handle truncating if the tabline is too long
    if total_length > truncation["max_length"] then
        truncation["strategy"] = "Basic"
        truncation["amount"] = truncation["total_length"] - truncation["max_length"]
        truncation["amount_per_tab"] = truncation["amount"] - #tabs
    end

    return M._format_tabline(tabs, truncation)
end

function M._tab_line()
    vim.o.tabline = "%!v:lua.require'dot.settings'._generate_tabline()"
end

function M.init()
    M._base()
    M._indentation()
    M._directories()
    M._tab_line()
end

return M
```

File `./config/nvim/lua/dot/util.lua`:
```
local vim = vim

local Log = require('dot.log')

local M = {}

function M.is_windows()
    -- TODO: Confirm this is right; only checked it on Linux
    return vim.loop.os_uname().sysname == "Windows"
end

function M.is_linux()
    return vim.loop.os_uname().sysname == "Linux"
end

function M.path_sep()
    if M.is_windows() then return "\\" else return "/" end
end

function M.str_join(sep, ...)
    return table.concat({...}, sep)
end

function M.path_join(...)
    return M.str_join(M.path_sep(), ...)
end

function M.tmp_dir()
    return M.path_join(os.getenv('HOME'), '.tmp', 'nvim')
end

function M.data_dir()
    return vim.fn.stdpath('data')
end

function M.config_dir()
    return vim.fn.stdpath('config')
end

function M.config_path()
    return M.path_join(M.config_dir(), "init.lua")
end

function M.is_int(n)
  return (type(n) == "number") and (math.floor(n) == n)
end

function M.is_string(n)
  return type(n) == "string"
end

function M.reload_config(config)
    if config == nil or not M.is_string(config) or string.len(config) == 0 then
        config = M.config_path()
    end

    vim.cmd("luafile " .. config)
end

function M.format_current_python_file()
    local command = "black " .. vim.api.nvim_buf_get_name(0) .. " 2>&1"
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    vim.cmd "edit"
    print(result)
end

function M.print_current_filetype()
    print(vim.bo.filetype)
end

function M.move_to_column(column)
    -- Get the current column
    local curr = vim.api.nvim_win_get_cursor(0)[2]

    -- Make sure the target column is valid
    if column == nil or not M.is_int(column) then
        column = 80
    end

    local insertion_count = (column - curr) - 1

    -- Make sure we aren't already past the target column
    if insertion_count <= 0 then
        print("Target column is less than or equal to current column")
        return
    end

    local insertion_string = ""
    for i = 1,insertion_count,1
    do
        insertion_string = insertion_string .. " "
    end

    local line = vim.api.nvim_get_current_line()
    local nline = line:sub(0, curr) .. insertion_string .. line:sub(curr + 1)
    vim.api.nvim_set_current_line(nline)
end

function M.close_tabs_to_right()
    local cur = vim.fn.tabpagenr()
    while cur < vim.fn.tabpagenr('$') do
        vim.cmd('tabclose ' .. (cur + 1))
    end
end

function M.is_wsl()
    local x = os.getenv("WSL_DISTRO_NAME")
    return type(x) == "string" and string.len(x) > 0
end

function M.directory_exists(path)
    return vim.fn.isdirectory(path) ~= 0
end

function M.file_exists(path)
   local f = io.open(path, "r")
   if f ~= nil then
       io.close(f)
       return true
   else
       return false
   end
end

-- Returns the current file path and line number underneath the cursor
-- formatted as:
-- path/to/file.cpp:42
function M.get_file_and_line()
    return M.str_join(':', vim.fn.expand('%'), vim.fn.line('.'))
end

function M.copy_file_and_line()
    local file_and_line = M.get_file_and_line()
    vim.fn.setreg('+', file_and_line)
end

--[[
  Truncates a string from the center if it exceeds the specified maximum
  length.

  The string is truncated by removing characters from the middle and replacing
  them with two periods ('..') if the length of the input string exceeds the
  specified maximum length. The resulting truncated string will have a total
  length not exceeding the max_length parameter.

  Example:
    truncate_center("VeryLongFileName.cpp", 12) => "VeryL..e.cpp"

  Parameters:
    str (string): The input string to be truncated.
    max_length (number): The maximum allowed length for the resulting string.

  Returns:
    string: The possibly truncated string.
]]
function M.truncate_center(str, max_length)
    local length = #str
    if length <= max_length then
        return str
    else
        local part_length = math.floor((max_length - 2) / 2)
        return str:sub(1, part_length) .. ".." .. str:sub(length - part_length + 1, length)
    end
end

-- Returns whether or not a buffer contains unsaved changes
function M.is_buffer_modified(buffer_index)
    return vim.fn.getbufvar(buffer_index, '&modified') == 1
end

return M
```

File `./config/nvim/lua/dot/lsp_clangd.lua`:
```
--[[

This file is responsible for setting up the language server for C++

Uses the clangd language server:
https://clangd.llvm.org/

Support for clangd in lspconfig:
https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/server_configurations/clangd.lua

]]--

local vim = vim

local Log = require('dot.log')
local Map = require('dot.map')

local M = {}

function M.configure()
    local status, lspconfig = pcall(require, 'lspconfig')
    if not status  then
        Log.warn('Failed to load lspconfig module')
        return
    end

    -- Requires clangd LSP, to install:
    -- sudo apt-get install clangd-12
    -- sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-12 100
    if vim.fn.executable('clangd') ~= 1 then
        return
    end

    -- Use an on_attach function to only map the following keys after the language
    -- server attaches to the current buffer
    local on_attach = function(client, buf)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- See `:help vim.lsp.*` for documentation on the below functions
        Map.nnoremapbs(buf, 'gD',    '<cmd>lua vim.lsp.buf.declaration()<cr>')
        Map.nnoremapbs(buf, 'gd',    '<Cmd>lua vim.lsp.buf.definition()<CR>')
        Map.nnoremapbs(buf, 'K',     '<Cmd>lua vim.lsp.buf.hover()<CR>')
        Map.nnoremapbs(buf, 'gi',    '<cmd>lua vim.lsp.buf.implementation()<CR>')
        Map.nnoremapbs(buf, 'gr',    '<cmd>lua vim.lsp.buf.references()<CR>')
        Map.nnoremapbs(buf, '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')

        -- Other supported LSP commands we could map
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.clear_references()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.code_action()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.completion()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.document_highlight()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.document_symbol()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.execute_command()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.format()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.incoming_calls()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.list_workspace_folders()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.outgoing_calls()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.rename()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.type_definition()<cr>')
        -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.workspace_symbol()<cr>')
    end

    -- This log file isn't rotated so it will grow infinitely. Keep logging off
    -- unless debugging issues with the language server, in which case, set this to
    -- "trace" or "debug" instead of "off".
    vim.lsp.set_log_level("off")

    lspconfig["clangd"].setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        },
        filetypes = { "c", "cpp" },
    }
end

return M
```

File `./config/nvim/lua/dot/treesitter.lua`:
```
local Log = require('dot.log')

local M = {}

function M.configure()
    local status, TreesitterConfigs = pcall(require, 'nvim-treesitter.configs')
    if not status  then
        Log.warn('Failed to load nvim-treesitter.configs module')
        return
    end

    TreesitterConfigs.setup({
        highlight = {
            enable = true,
            disable = {
                -- As of 2024-05-21, treesitter syntax highlighting for
                -- Markdown files has been causing problems so just disable it
                -- and use the built-in regex syntax highlighting. I'm doing
                -- this instead of removing it entirely from the list below
                -- because there are warnings in `:checkhealth` for lspsaga if
                -- markdown and markdown_inline aren't installed.
                "markdown",
            },
            additional_vim_regex_highlighting = false,
        },
        indent = {
            enable = false,
            disable = {},
        },
        -- The source of truth for the available parsers lives in this file:
        -- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/parsers.lua
        --
        -- Alternatively, `ensure_installed = "all"` is supported but that
        -- downloads a ton of parsers I don't care about and that were occasionally
        -- causing errors.
        ensure_installed = {
            "bash",
            "c",
            "c_sharp",
            "cmake",
            "commonlisp",
            "cpp",
            "css",
            "csv",
            "disassembly",
            "dockerfile",
            "elixir",
            "erlang",
            "gdscript",
            "git_rebase",
            "gitattributes",
            "gitcommit",
            "git_config",
            "gitignore",
            "go",
            "godot_resource",
            "gomod",
            "gosum",
            "gowork",
            "groovy",
            "hcl",
            "html",
            "ini",
            "java",
            "javascript",
            "json",
            "latex",
            "lua",
            "make",
            "markdown",
            "markdown_inline",
            "meson",
            "proto",
            "puppet",
            "python",
            "toml",
            "vim",
            "xml",
            "yaml",
        }
    })
end

return M
```

File `./config/nvim/lua/dot/wsl.lua`:
```
local M = {}

function M.init()
    vim.env.FZF_DEFAULT_COMMAND = 'fzf_cached_wsl'

    vim.g.clipboard = {
        name = "win32yank-wsl",
        copy = {
            ["+"] = "win32yank.exe -i --crlf",
            ["*"] = "win32yank.exe -i --crlf",
        },
        paste = {
            ["+"] = "win32yank.exe -o --lf",
            ["*"] = "win32yank.exe -o --lf",
        },
        cache_enabled = true,
    }
end

return M
```

File `./config/nvim/lua/dot/globals.lua`:
```
local vim = vim

local Util    = require('dot.util')
local VimPlug = require('dot.vim_plug')

local M = {}

function M._move_to_column(opts)
    local column = tonumber(opts.args)
    Util.move_to_column(column)
end

function M._reload_snippets(commands)
    vim.cmd('call UltiSnips#RefreshSnippets()')
end

function M._create_command(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts)
end

function M._create_commands(commands)
    for _, command in ipairs(commands) do
        M._create_command(unpack(command))
    end
end

function M.init()
    _G.close_tabs_to_right        = Util.close_tabs_to_right
    _G.copy_file_and_line         = Util.copy_file_and_line
    _G.format_current_python_file = Util.format_current_python_file
    _G.move_to_column             = Util.move_to_column
    _G.print_current_filetype     = Util.print_current_filetype
    _G.reload_config              = Util.reload_config

    _G.install_vim_plug           = VimPlug.install

    M._create_commands({
        { 'ReloadConfig',     Util.reload_config,       {} },
        { 'CloseTabsToRight', Util.close_tabs_to_right, {} },
        { 'MoveToColumn',     M._move_to_column,        { nargs = 1 } },
        { 'ReloadSnippets',   M._reload_snippets,       {} },
    })
end

return M
```

File `./config/nvim/lua/dot/vim_plug.lua`:
```
local vim = vim

local Log = require('dot.log')
local Util = require('dot.util')

local M = {
    path = Util.path_join(Util.data_dir(), 'site', 'autoload', 'plug.vim'),
    url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
}

function M.is_installed()
    return Util.file_exists(M.path)
end

function M.install()
    local curl_command = Util.str_join(' ', '!curl', '-fLo', M.path, '--create-dirs', M.url)
    Log.info('Installing vim-plug: ' .. curl_command)
    vim.cmd(curl_command)
end

function M.source()
    local source_command = 'source ' .. M.path
    Log.info('Sourcing vim-plug: ' .. source_command)
    vim.cmd(source_command)
end

function M.install_plugins()
    -- TODO: Untested and currently unused
    local autocmd_command = 'PlugInstall --sync'
    Log.info('Installing plugins: ' .. autocmd_command)
    vim.cmd(autocmd_command)
end

return M
```

File `./config/nvim/lua/dot/notifications.lua`:
```
local vim = vim

local Log = require('dot.log')

local M = {
    notifications = {},
}

function M.add(text)
    local location = M._get_location()
    table.insert(M.notifications, {
        filename = location['file'],
        lnum = location['line'],
        col = location['column'],
        text = text
    })
end

function M.any()
    return #M.notifications > 0
end

function M.display()
    vim.fn.setqflist(M.notifications, 'r')
end

function M._get_location()
    local info = debug.getinfo(3, "Sl")
    return {
        file = info.short_src,
        line = info.currentline,
        column = 1
    }
end

return M
```

File `./config/nvim/lua/dot/mappings.lua`:
```
local Map = require('dot.map')

local M = {}

function M._tabs()
    -- Open current file in a second tab and make it the last tab
    Map.nnoremap('<leader><tab>c', ':tab split<CR>:tabm<CR>')

    -- Fuzzy find opener for windows/tabs
    Map.nnoremap('<leader><tab>o', ':Windows<cr>')

    -- Next/Previous
    Map.nnoremap('<leader><tab>n', ':tabnext<cr>')
    Map.nnoremap('<leader><tab>p', ':tabprevious<cr>')

    -- Close tabs to right
    Map.nnoremap('<leader><tab>q', ':CloseTabsToRight<cr>')

    -- Tab navigation
    Map.nnoremap('<A-F1>', '1gt')
    Map.nnoremap('<A-F2>', '2gt')
    Map.nnoremap('<A-F3>', '3gt')
    Map.nnoremap('<A-F4>', '4gt')
    Map.nnoremap('<A-F5>', '5gt')
    Map.nnoremap('<A-F6>', '6gt')
    Map.nnoremap('<A-F7>', '7gt')
    Map.nnoremap('<A-F8>', '8gt')
    Map.nnoremap('<A-F9>', '9gt')
    Map.nnoremap('<A-F0>', '10gt')

    -- Tab navigation alternative
    Map.nnoremap('<leader>1', '1gt')
    Map.nnoremap('<leader>2', '2gt')
    Map.nnoremap('<leader>3', '3gt')
    Map.nnoremap('<leader>4', '4gt')
    Map.nnoremap('<leader>5', '5gt')
    Map.nnoremap('<leader>6', '6gt')
    Map.nnoremap('<leader>7', '7gt')
    Map.nnoremap('<leader>8', '8gt')
    Map.nnoremap('<leader>9', '9gt')
    Map.nnoremap('<leader>0', '10gt')
end

function M._buffers()
    Map.nnoremap('<Leader>bn', ':bn<CR>')
    Map.nnoremap('<Leader>bp', ':bp<CR>')
    Map.nnoremap('<Leader>bf', ':n<Space>')
    Map.nnoremap('<Leader>bd', ':bd<CR>')
    Map.nnoremap('<leader>bl', ':ls<cr>:buffer<space>')

    -- TODO: This has nothing to do with buffers
    Map.nnoremap('<Leader>be', ':Ex<CR>')
end

function M._quickfix()
    Map.nnoremap('<Leader>cn', ':cn<CR>')
    Map.nnoremap('<Leader>cp', ':cp<CR>')
    Map.nnoremap('<Leader>co', ':copen<CR>')
    Map.nnoremap('<Leader>cc', ':cclose<CR>')
end

-- TODO: We can probably delete these; I very rarely remember to use them
function M._syntax()
    Map.nnoremap('<leader>ssx', ':set syntax=')
    Map.nnoremap('<leader>ssg', ':set syntax=groovy<cr>')
end

function M._resize()
    -- Resize current focused window
    Map.nnoremaps('<leader><Up>', ':resize +5<cr>')
    Map.nnoremaps('<leader><Down>', ':resize -5<cr>')
    Map.nnoremaps('<leader><Right>', ':vertical resize +5<cr>')
    Map.nnoremaps('<leader><Left>', ':vertical resize -5<cr>')
end

function M._misc()
    -- Run gmake
    Map.nnoremap('<Leader>m', ':make<CR>')

    -- Generate ctags
    Map.nnoremap('<Leader>[', ':!ctags -R<CR>')

    -- Save out all buffers
    Map.nnoremaps('<leader>w', ':wa<cr>')

    -- Clear search highlighting
    Map.nnoremaps('<leader><esc>', ':noh<cr>')

    -- Print the current file path
    Map.nnoremaps('<leader>p', ':echo @%<cr>')

    -- Copy file path and line number of current line to clipboard
    Map.nnoremaps('<leader>y', ':lua copy_file_and_line()<cr>')

    -- Execute normal command on visual selection
    Map.xnoremap('<leader>n', ':normal<space>')

    -- Format the current Python file with black
    Map.ft_nnoremap('python', '<Leader>q', ':lua format_current_python_file()<CR>')
end

function M.init()
    -- Set the Leader key. I leave the leader key as '\' and remap ' ' to it
    -- instead of setting ' ' as the leader. This makes showcmd more useful.
    Map.map('<Space>', '<Leader>')

    M._tabs()
    M._buffers()
    M._quickfix()
    M._syntax()
    M._resize()
    M._misc()

    -- Reload/edit config
    Map.nnoremaps('<leader>x', ':e ~/dot/config/nvim/init.lua<cr>')
    Map.nnoremaps('<leader>r', ':lua reload_config()<CR>')
end

return M
```

File `./config/nvim/lua/dot/lsp_jedi.lua`:
```
-- This file is responsible for setting up the language server for Python

local M = {}

local Log = require('dot.log')
local Map = require('dot.map')

function M.configure()
    local status, lspconfig = pcall(require, 'lspconfig')
    if not status  then
        Log.warn('Failed to load lspconfig module')
        return
    end

    -- Requires Jedi LSP, to install:
    -- python -m pip install -U jedi-language-server
    if vim.fn.executable('jedi-language-server') ~= 1 then
        return
    end

    -- Use an on_attach function to only map the following keys after the language
    -- server attaches to the current buffer
    local on_attach = function(client, buf)
        -- See `:help vim.lsp.*` for documentation on the below functions
        Map.nnoremapbs(buf, 'gd',    '<Cmd>lua vim.lsp.buf.definition()<CR>')
        Map.nnoremapbs(buf, 'gr',    '<cmd>lua vim.lsp.buf.references()<CR>')
        Map.nnoremapbs(buf, 'gi',    '<cmd>lua vim.lsp.buf.implementation()<CR>')
        Map.nnoremapbs(buf, 'K',     '<Cmd>lua vim.lsp.buf.hover()<CR>')
        Map.nnoremapbs(buf, '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
    end

    lspconfig["jedi_language_server"].setup {
        on_attach = on_attach,
        filetypes = { "python" },
    }
end

return M
```

File `./config/nvim/lua/dot/lsp_gopls.lua`:
```
local M = {}

local Log = require('dot.log')
local Map = require('dot.map')

function M.configure()
    local status, lspconfig = pcall(require, 'lspconfig')
    if not status  then
        Log.warn('Failed to load lspconfig module')
        return
    end

    -- Requires gopls which should be installed by default with Go
    if vim.fn.executable('gopls') ~= 1 then
        return
    end

    -- Use an on_attach function to only map the following keys after the
    -- language server attaches to the current buffer
    local on_attach = function(client, buf)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- See `:help vim.lsp.*` for documentation on the below functions
        Map.nnoremapbs(buf, '<leader>ld', '<Cmd>lua vim.lsp.buf.definition()<CR>')
        Map.nnoremapbs(buf, 'gr',         '<cmd>lua vim.lsp.buf.references()<CR>')
        Map.nnoremapbs(buf, 'gi',         '<cmd>lua vim.lsp.buf.implementation()<CR>')
        Map.nnoremapbs(buf, 'K',          '<Cmd>lua vim.lsp.buf.hover()<CR>')
        Map.nnoremapbs(buf, '<C-k>',      '<cmd>lua vim.lsp.buf.signature_help()<CR>')
    end

    -- https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/server_configurations/gopls.lua
    lspconfig["gopls"].setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        }
    }
end

return M
```
