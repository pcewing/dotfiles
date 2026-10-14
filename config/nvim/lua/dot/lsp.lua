--[[

This file is responsible for setting up language servers.

nvim-lspconfig only ships the server defaults now (in its "lsp/" directory);
it is no longer a "framework". Overrides are registered with vim.lsp.config()
and servers are activated with vim.lsp.enable(). See :help lspconfig-nvim-0.11

Neovim provides these LSP mappings itself, so they are not defined here:

    K          hover                    (buffer-local, set on attach)
    grr        references
    gri        implementation
    grn        rename
    gra        code action              (normal and visual mode)
    grt        type definition
    grx        run code lens
    gO         document symbols
    <C-S>      signature help           (insert and select mode)
    [d / ]d    previous/next diagnostic
    <C-W>d     show diagnostic under the cursor in a float
    <C-]>      go to definition         (via 'tagfunc')
    <C-x><C-o> completion               (via 'omnifunc')

Completion also opens automatically after the server's trigger characters
(e.g. "." or "->"); see on_lsp_attach below. In the completion menu:

    <C-n>/<C-p>  next/previous item
    <C-y>        accept the item (expands LSP snippets, applies auto-imports)
    <C-e>        close the menu

This file adds gd, <C-k>, gD (clangd only), and <leader>fm, a live fzf picker
for workspace symbols (see lsp_symbols.lua).

See :help lsp-defaults and :help lsp-completion

]]

local vim = vim

local LspSymbols = require('dot.lsp_symbols')

local M = {}

-- Mappings installed in every buffer an enabled server attaches to. Values are
-- vim.lsp.buf function names.
local common_keys = {
    gd = 'definition',
    ['<C-k>'] = 'signature_help',
}

-- Servers are only enabled when their executable is on PATH, and use
-- nvim-lspconfig's defaults as-is. `keys` adds to `common_keys`. To override a
-- default, call vim.lsp.config(name, { ... }) before vim.lsp.enable(name).
local servers = {
    clangd = {
        executable = 'clangd',
        keys = { gD = 'declaration' },
    },
    gopls = {
        executable = 'gopls',
    },
    jedi_language_server = {
        executable = 'jedi-language-server',
    },
}

local function map_keys(buf, keys)
    for lhs, method in pairs(keys) do
        vim.keymap.set('n', lhs, vim.lsp.buf[method], {
            buffer = buf,
            silent = true,
            desc = 'vim.lsp.buf.' .. method .. '()',
        })
    end
end

-- Buffer-local mappings are installed from a LspAttach autocmd rather than
-- from the server's "on_attach" callback. Passing on_attach to
-- vim.lsp.config() would replace nvim-lspconfig's default on_attach, which for
-- clangd is what creates the :LspClangdSwitchSourceHeader and
-- :LspClangdShowSymbolInfo commands. See :help lsp-attach
local function on_lsp_attach(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
        return
    end

    local server = servers[client.name]
    if server == nil then
        return
    end

    map_keys(args.buf, common_keys)
    map_keys(args.buf, server.keys or {})

    vim.keymap.set('n', '<leader>fm', LspSymbols.pick, {
        buffer = args.buf,
        desc = 'Find LSP workspace symbol (fzf)',
    })

    -- Built-in LSP completion. autotrigger opens the menu when the server's
    -- trigger characters are typed; elsewhere use <C-x><C-o>. This also
    -- expands snippet items and applies the server's additional edits (such as
    -- clangd adding an #include) when an item is accepted with <C-y>.
    vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
end

function M.configure()
    -- This log file isn't rotated so it will grow infinitely. Keep logging off
    -- unless debugging issues with the language server, in which case, set this to
    -- "trace" or "debug" instead of "off".
    vim.lsp.log.set_level('off')

    -- clear = true keeps a re-run of this function (e.g. on config reload) from
    -- stacking duplicate autocmds
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('dot_lsp', { clear = true }),
        callback = on_lsp_attach,
    })

    for name, server in pairs(servers) do
        if vim.fn.executable(server.executable) == 1 then
            vim.lsp.enable(name)
        end
    end
end

return M
