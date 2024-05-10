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
