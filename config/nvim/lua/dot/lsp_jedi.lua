-- This file is responsible for setting up the language server for Python

local M = {}

local Map = require('dot.map')

-- Buffer-local mappings are installed from a LspAttach autocmd rather than
-- from the server's "on_attach" callback, so that any default on_attach that
-- nvim-lspconfig ships for jedi-language-server is left intact.
-- See :help lsp-attach
local function attach(buf)
    -- See `:help vim.lsp.*` for documentation on the below functions
    Map.nnoremapbs(buf, 'gd',    '<Cmd>lua vim.lsp.buf.definition()<CR>')
    Map.nnoremapbs(buf, 'gr',    '<cmd>lua vim.lsp.buf.references()<CR>')
    Map.nnoremapbs(buf, 'gi',    '<cmd>lua vim.lsp.buf.implementation()<CR>')
    Map.nnoremapbs(buf, 'K',     '<Cmd>lua vim.lsp.buf.hover()<CR>')
    Map.nnoremapbs(buf, '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
end

function M.configure()
    -- Requires Jedi LSP, to install:
    -- python -m pip install -U jedi-language-server
    if vim.fn.executable('jedi-language-server') ~= 1 then
        return
    end

    -- clear = true keeps a re-run of this function (e.g. on config reload) from
    -- stacking duplicate autocmds
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('dot_lsp_jedi', { clear = true }),
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client == nil or client.name ~= 'jedi_language_server' then
                return
            end
            attach(args.buf)
        end,
    })

    -- See :help lspconfig-nvim-0.11
    vim.lsp.config('jedi_language_server', {
        filetypes = { "python" },
    })
    vim.lsp.enable('jedi_language_server')
end

return M
