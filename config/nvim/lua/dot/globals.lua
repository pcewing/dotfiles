local vim = vim

local Util    = require('dot.util')
local VimPlug = require('dot.vim_plug')

local M = {}

function M._move_to_column(opts)
    local column = tonumber(opts.args)
    Util.move_to_column(column)
end

function M._copy_code_snippet(opts)
    Util.copy_code_snippet(opts.line1, opts.line2)
end

function M._reload_snippets()
    vim.cmd('call UltiSnips#RefreshSnippets()')
end

function M.init()
    vim.api.nvim_create_user_command('ReloadConfig', function() Util.reload_config() end, {})
    vim.api.nvim_create_user_command('CloseTabsToRight', Util.close_tabs_to_right, {})
    vim.api.nvim_create_user_command('MoveToColumn', M._move_to_column, { nargs = 1 })
    vim.api.nvim_create_user_command('ReloadSnippets', M._reload_snippets, {})
    vim.api.nvim_create_user_command('CopyCodeSnippet', M._copy_code_snippet, { range = true })
    vim.api.nvim_create_user_command('InstallVimPlug', function() VimPlug.install() end, {})
end

return M
