local Util    = require('dot.util')
local VimPlug = require('dot.vim_plug')

local M = {}

function M.init()
    _G.close_tabs_to_right = Util.close_tabs_to_right
    _G.copy_file_and_line = Util.copy_file_and_line
    _G.format_current_python_file = Util.format_current_python_file
    _G.reload_config = Util.reload_config
    _G.install_vim_plug = VimPlug.install
end

return M
