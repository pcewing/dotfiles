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
