-- This file is responsible for setting up the language server for Python

-- Requires Jedi LSP, to install:
-- python -m pip install -U jedi-language-server
if vim.fn.executable('jedi-language-server') ~= 1 then
    return
end

-- Use an on_attach function to only map the following keys after the language
-- server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>',        opts)
  buf_set_keymap('n', 'gr',         '<cmd>lua vim.lsp.buf.references()<CR>',        opts)
  buf_set_keymap('n', 'gi',         '<cmd>lua vim.lsp.buf.implementation()<CR>',    opts)
  buf_set_keymap('n', 'K',          '<Cmd>lua vim.lsp.buf.hover()<CR>',             opts)
  buf_set_keymap('n', '<C-k>',      '<cmd>lua vim.lsp.buf.signature_help()<CR>',    opts)
end

local nvim_lsp = require('lspconfig')

nvim_lsp["jedi_language_server"].setup {
    on_attach = on_attach,
    filetypes = { "python" },
}
