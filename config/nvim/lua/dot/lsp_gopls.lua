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
