--[[

This file is responsible for setting up the language server for C++

Uses the clangd language server:
https://clangd.llvm.org/

Support for clangd in lspconfig:
https://github.com/neovim/nvim-lspconfig/blob/master/lsp/clangd.lua

]]--

local vim = vim

local Map = require('dot.map')

local M = {}

-- Buffer-local mappings are installed from a LspAttach autocmd rather than
-- from the server's "on_attach" callback. Passing on_attach to
-- vim.lsp.config() would replace nvim-lspconfig's default clangd on_attach,
-- which is what creates the :LspClangdSwitchSourceHeader and
-- :LspClangdShowSymbolInfo commands. See :help lsp-attach
local function attach(buf)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- See `:help vim.lsp.*` for documentation on the below functions
    Map.nnoremapbs(buf, 'gD',    '<cmd>lua vim.lsp.buf.declaration()<cr>')
    Map.nnoremapbs(buf, 'gd',    '<Cmd>lua vim.lsp.buf.definition()<CR>')
    Map.nnoremapbs(buf, 'K',     '<Cmd>lua vim.lsp.buf.hover()<CR>')
    Map.nnoremapbs(buf, 'gi',    '<cmd>lua vim.lsp.buf.implementation()<CR>')
    Map.nnoremapbs(buf, 'gr',    '<cmd>lua vim.lsp.buf.references()<CR>')
    Map.nnoremapbs(buf, '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')

    -- Other supported LSP commands we could map
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.clear_references()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.code_action()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.completion()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.document_highlight()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.document_symbol()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.execute_command()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.format()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.incoming_calls()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.list_workspace_folders()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.outgoing_calls()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.rename()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.type_definition()<cr>')
    -- Map.nnoremapbs(buf, 'foo', '<cmd>lua vim.lsp.buf.workspace_symbol()<cr>')
end

function M.configure()
    -- Requires clangd LSP, to install:
    -- sudo apt-get install clangd-12
    -- sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-12 100
    if vim.fn.executable('clangd') ~= 1 then
        return
    end

    -- This log file isn't rotated so it will grow infinitely. Keep logging off
    -- unless debugging issues with the language server, in which case, set this to
    -- "trace" or "debug" instead of "off".
    vim.lsp.log.set_level("off")

    -- clear = true keeps a re-run of this function (e.g. on config reload) from
    -- stacking duplicate autocmds
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('dot_lsp_clangd', { clear = true }),
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client == nil or client.name ~= 'clangd' then
                return
            end
            attach(args.buf)
        end,
    })

    -- nvim-lspconfig only ships the server defaults now (in its "lsp/"
    -- directory); it is no longer a "framework". Register overrides with
    -- vim.lsp.config() and activate them with vim.lsp.enable(). See
    -- :help lspconfig-nvim-0.11
    --
    -- No on_attach here on purpose: the mappings come from the LspAttach
    -- autocmd above so lspconfig's default clangd on_attach still runs.
    vim.lsp.config('clangd', {
        flags = {
            debounce_text_changes = 150,
        },
        filetypes = { "c", "cpp" },
    })
    vim.lsp.enable('clangd')
end

return M
