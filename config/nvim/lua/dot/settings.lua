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

function M._generate_tabline_tab_label(tab_index)
    local max_filename_length = 48

    local s = ""

    local buflist = vim.fn.tabpagebuflist(tab_index)
    local winnr = vim.fn.tabpagewinnr(tab_index)
    local bufname = vim.fn.fnamemodify(vim.fn.bufname(buflist[winnr]), ":t")
    bufname = Util.truncate_center(bufname, max_filename_length)

    local is_modified = false
    for _, i in ipairs(buflist) do
        if Util.is_buffer_modified(i) then
            Log.info("buffer " .. i .. " is modified")
            is_modified = true
            break
        end
    end

    -- Add an indicator if any buffer in the tab has unsaved changes
    if is_modified then
        Log.info("Adding modified indicator")
        s = s .. "+"
    else
        s = s .. " "
    end

    -- Add the tab index so it's easier to navigate to specific tabs
    s = s .. "[" .. tab_index .. "]"

    -- Append the focused buffer's truncated file name or if it doesn't have
    -- one just label it UNSAVED
    if #bufname > 0 then
        return s .. " " .. bufname
    else
        return  s .. " UNSAVED"
    end
end

function M._generate_tabline_tab(i)
    local s = ""

    -- Set whether or not the tab is selected
    if i == vim.fn.tabpagenr() then
        s = s .. '%#TabLineSel#'
    else
        s = s .. '%#TabLine#'
    end

    -- Set the tab page number for navigation
    s = s .. '%' .. i .. 'T'

    -- Set the tab label
    s = s .. " " .. M._generate_tabline_tab_label(i) .. " "

    return s
end

function M._generate_tabline()
    local s = ""

    for i = 1, vim.fn.tabpagenr('$') do
        s = s .. M._generate_tabline_tab(i)
    end

    -- After the last tab fill with TabLineFill and reset tab page nr
    s = s .. '%#TabLineFill#%T'

    -- Right-align the label to close the current tab page
    if vim.fn.tabpagenr('$') > 1 then
        s = s .. '%=%#TabLine#%999Xclose'
    end

    return s
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
