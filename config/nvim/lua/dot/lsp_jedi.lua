-- This file is responsible for setting up the language server for Python

local M = {}

local Map = require('dot.map')

function M.configure()
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

    -- See :help lspconfig-nvim-0.11
    vim.lsp.config('jedi_language_server', {
        on_attach = on_attach,
        filetypes = { "python" },
    })
    vim.lsp.enable('jedi_language_server')
end

return M
