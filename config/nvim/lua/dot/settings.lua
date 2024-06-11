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

function M.init()
    M._base()
    M._indentation()
    M._directories()
end

return M
