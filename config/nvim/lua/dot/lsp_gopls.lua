local M = {}

local Map = require('dot.map')

-- Buffer-local mappings are installed from a LspAttach autocmd rather than
-- from the server's "on_attach" callback, so that any default on_attach that
-- nvim-lspconfig ships for gopls is left intact. See :help lsp-attach
local function attach(buf)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- See `:help vim.lsp.*` for documentation on the below functions
    Map.nnoremapbs(buf, '<leader>ld', '<Cmd>lua vim.lsp.buf.definition()<CR>')
    Map.nnoremapbs(buf, 'gr',         '<cmd>lua vim.lsp.buf.references()<CR>')
    Map.nnoremapbs(buf, 'gi',         '<cmd>lua vim.lsp.buf.implementation()<CR>')
    Map.nnoremapbs(buf, 'K',          '<Cmd>lua vim.lsp.buf.hover()<CR>')
    Map.nnoremapbs(buf, '<C-k>',      '<cmd>lua vim.lsp.buf.signature_help()<CR>')
end

function M.configure()
    -- Requires gopls which should be installed by default with Go
    if vim.fn.executable('gopls') ~= 1 then
        return
    end

    -- clear = true keeps a re-run of this function (e.g. on config reload) from
    -- stacking duplicate autocmds
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('dot_lsp_gopls', { clear = true }),
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client == nil or client.name ~= 'gopls' then
                return
            end
            attach(args.buf)
        end,
    })

    -- See :help lspconfig-nvim-0.11
    vim.lsp.config('gopls', {
        flags = {
            debounce_text_changes = 150,
        }
    })
    vim.lsp.enable('gopls')
end

return M
