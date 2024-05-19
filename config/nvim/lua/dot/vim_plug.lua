local vim = vim

local Log = require('dot.log')
local Util = require('dot.util')

local M = {
    path = Util.path_join(Util.data_dir(), 'site', 'autoload', 'plug.vim'),
    url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
}

function M.is_installed()
    return Util.file_exists(M.path)
end

function M.install()
    local curl_command = Util.str_join(' ', '!curl', '-fLo', M.path, '--create-dirs', M.url)
    Log.info('Installing vim-plug: ' .. curl_command)
    vim.cmd(curl_command)
end

function M.source()
    local source_command = 'source ' .. M.path
    Log.info('Sourcing vim-plug: ' .. source_command)
    vim.cmd(source_command)
end

function M.install_plugins()
    -- TODO: Untested and currently unused
    local autocmd_command = 'PlugInstall --sync'
    Log.info('Installing plugins: ' .. autocmd_command)
    vim.cmd(autocmd_command)
end

return M
