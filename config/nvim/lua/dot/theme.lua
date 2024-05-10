local Util = require('dot.util')

local M = {}

M.init = function()
    -- Start flavours - nvim

    -- Base16 Outrun Dark

    -- Loads the scheme from:
    -- https://github.com/chriskempson/base16-vim

    vim.g.base16colorspace = 256
    vim.cmd('colorscheme base16-outrun-dark')
    -- End flavours - nvim

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

return M
