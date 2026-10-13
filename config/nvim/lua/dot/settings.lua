local Util = require('dot.util')
local Log = require('dot.log')

local M = {}

-- Base settings. Only options that differ from Neovim's defaults are set here;
-- see :help vim-differences for the defaults. Notable ones relied on: 'hidden'
-- (switch away from modified buffers without saving them), 'belloff' (silences
-- all bells), 'backspace', 'showcmd', 'autoread', 'ruler', and 'history'.
function M._base()
    vim.opt.number = true                             -- Show line numbers
    vim.opt.guicursor = 'a:blinkon0'                  -- Disable cursor blink
    vim.opt.autowrite = true                          -- Write the file on :make
    vim.opt.splitright = true                         -- When splitting vertically, the new pane should be on the right
    vim.opt.splitbelow = true                         -- When splitting horizontally, the new pane should be on the bottom
    vim.opt.clipboard = "unnamed,unnamedplus"         -- Use system clipboard if possible
    vim.opt.cursorline = true                         -- Add a visual indicator to the line the cursor is on

    -- Show the completion menu even for a single match, don't select (and
    -- insert) the first match automatically, and show item documentation in a
    -- popup. "noselect" is what makes LSP autocompletion usable: without it,
    -- the menu that opens after typing "." would insert its first item.
    vim.opt.completeopt = { 'menuone', 'noselect', 'popup' }

    -- Use global status line
    vim.opt.laststatus = 3
end

-- Indentation settings
function M._indentation()
    vim.opt.smartindent = true
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
    -- directory for each editing session. This works on Windows too; Neovim
    -- accepts and recommends "//" over "\\" on Win32 (see 'backupdir').
    local dir = Util.tmp_dir() .. "//"

    Log.debug('Setting backup dir to ' .. dir)

    -- Backup and swap directories; the double slashes are important here
    vim.opt.backupdir = { dir, "." }
    vim.opt.directory = { dir, "." }
end

-- The shortest a file name in the tabline is cut down to, not counting the "…"
-- that marks it as shortened
local min_name_length = 4

-- Each tab is labelled "+[n] name": "+" when a buffer visible in the tab has
-- unsaved changes, the tab number (for {n}gt), and the name of the file in the
-- tab's focused window. When the labels don't fit, the longest names are
-- shortened first, from the left ("…e_name.c"), down to min_name_length. If
-- they still don't fit, the trailing "%<" makes Neovim cut off the tabs on the
-- right (it would otherwise cut from the left).
function M._generate_tabline()
    local count = vim.fn.tabpagenr('$')
    local current = vim.fn.tabpagenr()

    local tabs = {}
    for i = 1, count do
        local buffers = vim.fn.tabpagebuflist(i)
        local name = vim.fn.fnamemodify(vim.fn.bufname(buffers[vim.fn.tabpagewinnr(i)]), ':t')
        if name == '' then
            name = 'UNSAVED'
        end

        local is_modified = false
        for _, buffer in ipairs(buffers) do
            if vim.bo[buffer].modified then
                is_modified = true
                break
            end
        end

        tabs[i] = {
            prefix = (is_modified and '+' or ' ') .. '[' .. i .. '] ',
            name = name,
            width = vim.fn.strdisplaywidth(name),
        }
    end

    -- Total width of the tabline if no name is wider than max_width (one space
    -- separates the tabs)
    local function total_width(max_width)
        local total = count - 1
        for _, tab in ipairs(tabs) do
            total = total + #tab.prefix + math.min(tab.width, max_width)
        end
        return total
    end

    -- Lower the widest allowed name until the tabs fit. A shortened name keeps
    -- max_width - 1 cells and adds the "…".
    local max_width = 0
    for _, tab in ipairs(tabs) do
        max_width = math.max(max_width, tab.width)
    end
    while max_width > min_name_length + 1 and total_width(max_width) > vim.o.columns do
        max_width = max_width - 1
    end

    local labels = {}
    for i, tab in ipairs(tabs) do
        local name = tab.name
        if tab.width > max_width then
            while vim.fn.strdisplaywidth(name) > max_width - 1 do
                name = vim.fn.strcharpart(name, 1)
            end
            name = '…' .. name
        end

        -- %nT makes a mouse click select the tab; "%" in a file name must be
        -- doubled so it isn't read as a tabline item
        labels[i] = (i == current and '%#TabLineSel#' or '%#TabLine#')
            .. '%' .. i .. 'T' .. tab.prefix .. (name:gsub('%%', '%%%%'))
    end

    return table.concat(labels, '%#TabLineFill# ') .. '%#TabLineFill#%T%<'
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
