local vim = vim

local Log = require('dot.log')
local Util = require('dot.util')

local M = {
    path = Util.path_join(Util.data_dir(), 'site', 'autoload', 'plug.vim'),
    url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
}

-- curl writes a multi-line progress meter before any error, so pull out the
-- last non-empty line (e.g. "curl: (6) Could not resolve host: ...") to get a
-- message that is actually useful in a notification.
local function last_line(text)
    local result = ''
    for line in (text or ''):gmatch('[^\r\n]+') do
        if line:match('%S') then
            result = vim.trim(line)
        end
    end
    return result
end

function M.is_installed()
    return Util.file_exists(M.path)
end

function M.install()
    -- Pass the command as a list so Neovim runs curl directly instead of going
    -- through a shell. A path containing spaces -- for example a Windows
    -- profile such as C:\Users\John Doe\... -- is then passed through intact,
    -- where a concatenated command string would split it into two arguments.
    local command = { 'curl', '-fLo', M.path, '--create-dirs', M.url }
    Log.info('Installing vim-plug: ' .. table.concat(command, ' '))

    -- vim.system throws if curl itself cannot be run (e.g. it is not on PATH),
    -- so keep that failure path separate from a non-zero curl exit code.
    local ok, result = pcall(function()
        return vim.system(command, { text = true }):wait()
    end)

    if not ok or result.code ~= 0 or result.signal ~= 0 then
        local detail = ok and last_line(result.stderr) or tostring(result)
        if detail == '' then
            detail = 'curl did not report an error message'
        end

        local message = 'Failed to install vim-plug: ' .. detail
        Log.error(message)
        vim.notify(message, vim.log.levels.ERROR)
        return false
    end

    return true
end

function M.install_plugins()
    -- TODO: Untested and currently unused
    local autocmd_command = 'PlugInstall --sync'
    Log.info('Installing plugins: ' .. autocmd_command)
    vim.cmd(autocmd_command)
end

return M
