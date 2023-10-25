--[[

This file is responsible for setting up the language server for C++

Uses the clangd language server:
https://clangd.llvm.org/

Support for clangd in lspconfig:
https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/server_configurations/clangd.lua

]]--

-- Requires clangd LSP, to install:
-- sudo apt-get install clangd-12
-- sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-12 100
if vim.fn.executable('clangd') ~= 1 then
    return
end

-- Use an on_attach function to only map the following keys after the language
-- server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', '<leader>ld', '<Cmd>lua vim.lsp.buf.definition()<CR>',        opts)
  buf_set_keymap('n', 'gr',         '<cmd>lua vim.lsp.buf.references()<CR>',        opts)
  buf_set_keymap('n', 'gi',         '<cmd>lua vim.lsp.buf.implementation()<CR>',    opts)
  buf_set_keymap('n', 'K',          '<Cmd>lua vim.lsp.buf.hover()<CR>',             opts)
  buf_set_keymap('n', '<C-k>',      '<cmd>lua vim.lsp.buf.signature_help()<CR>',    opts)
end

vim.lsp.set_log_level 'trace'

local nvim_lsp = require('lspconfig')

nvim_lsp["clangd"].setup {
    on_attach = on_attach,
    flags = {
        debounce_text_changes = 150,
    },
    filetypes = { "c", "cpp" },
}
