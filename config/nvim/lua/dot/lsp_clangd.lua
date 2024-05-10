--[[

This file is responsible for setting up the language server for C++

Uses the clangd language server:
https://clangd.llvm.org/

Support for clangd in lspconfig:
https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/server_configurations/clangd.lua

]]--

local vim = vim

local Log = require('dot.log')
local Map = require('dot.map')

local M = {}

function M.configure()
    local status, lspconfig = pcall(require, 'lspconfig')
    if not status  then
        Log.warn('Failed to load lspconfig module')
        return
    end

    -- Requires clangd LSP, to install:
    -- sudo apt-get install clangd-12
    -- sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-12 100
    if vim.fn.executable('clangd') ~= 1 then
        return
    end

    -- Use an on_attach function to only map the following keys after the language
    -- server attaches to the current buffer
    local on_attach = function(client, buf)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

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

    -- This log file isn't rotated so it will grow infinitely. Keep logging off
    -- unless debugging issues with the language server, in which case, set this to
    -- "trace" or "debug" instead of "off".
    vim.lsp.set_log_level("off")

    lspconfig["clangd"].setup {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150,
        },
        filetypes = { "c", "cpp" },
    }
end

return M
