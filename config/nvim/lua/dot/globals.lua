local vim = vim

local Util    = require('dot.util')
local VimPlug = require('dot.vim_plug')

local M = {}

function M._move_to_column(opts)
    local column = tonumber(opts.args)
    Util.move_to_column(column)
end

function M._create_command(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts)
end

function M._create_commands(commands)
    for _, command in ipairs(commands) do
        M._create_command(unpack(command))
    end
end

function M.init()
    _G.close_tabs_to_right        = Util.close_tabs_to_right
    _G.copy_file_and_line         = Util.copy_file_and_line
    _G.format_current_python_file = Util.format_current_python_file
    _G.move_to_column             = Util.move_to_column
    _G.print_current_filetype     = Util.print_current_filetype
    _G.reload_config              = Util.reload_config

    _G.install_vim_plug           = VimPlug.install

    M._create_commands({
        { 'ReloadConfig',     Util.reload_config,       {} },
        { 'CloseTabsToRight', Util.close_tabs_to_right, {} },
        { 'MoveToColumn',     M._move_to_column,        { nargs = 1 } }
    })
end

return M
