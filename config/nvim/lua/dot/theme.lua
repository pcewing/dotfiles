local Log           = require('dot.log')
local Notifications = require('dot.notifications')
local Util          = require('dot.util')

local M = {}

function M._color_scheme()
    -- Start flavours - nvim
    local color_scheme = 'base16-outrun-dark'
    -- End flavours - nvim
    
    -- CRITICAL FOR NEOVIDE / GUI ON WINDOWS: Enable true color support
    vim.opt.termguicolors = true 
    vim.g.base16colorspace = 256

    local status, _ = pcall(vim.cmd, 'colorscheme ' .. color_scheme)
    if not status then
        Notifications.add('Colorscheme ' .. color_scheme .. ' is not installed; install it via `:PlugInstall`')
    else
        Log.info('Color scheme successfully set to ' .. color_scheme)
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
    -- Force theme loading to execute after Neovim and Neovide UI channels
    -- fully initialize
    --vim.api.nvim_create_autocmd('VimEnter', {
    vim.api.nvim_create_autocmd('UIEnter', {
        callback = function()
            M._color_scheme()
            M._background()
        end
    })
end

return M
