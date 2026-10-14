local vim = vim

local Log = require('dot.log')

local M = {}

function M.is_windows()
    -- Note: vim.loop.os_uname().sysname reports "Windows_NT" on Windows, so it
    -- can't be used here. Neovim's own feature detection is reliable on both
    -- Windows and Linux.
    return vim.fn.has('win32') == 1
end

function M.is_linux()
    return vim.fn.has('linux') == 1
end

-- Returns the current user's home directory. os.getenv('HOME') is not set on
-- Windows (which uses USERPROFILE instead), so rely on Neovim's '~' expansion,
-- which resolves the home directory correctly on both Windows and Linux.
function M.home_dir()
    return vim.fn.expand('~')
end

function M.tmp_dir()
    return vim.fs.joinpath(M.home_dir(), '.tmp', 'nvim')
end

function M.config_path()
    return vim.fs.joinpath(vim.fn.stdpath('config'), 'init.lua')
end

-- Returns whether an environment variable is set to a non-empty value. An empty
-- variable counts as unset, matching Neovim's own `!empty($VAR)` checks.
function M.env_is_set(name)
    local value = vim.env[name]
    return value ~= nil and value ~= ''
end

-- Re-runs init.lua, which also forgets the cached dot.* modules so that changes
-- to them are picked up.
function M.reload_config()
    vim.cmd.luafile(M.config_path())
end

-- Formats the current file with black and reloads it. The file name is passed
-- as an argument rather than through a shell, so spaces or shell characters in
-- it are harmless.
function M.format_current_python_file()
    local command = { 'black', vim.api.nvim_buf_get_name(0) }

    -- vim.system throws if black itself cannot be run (e.g. it is not on PATH)
    local ok, result = pcall(function()
        return vim.system(command, { text = true }):wait()
    end)
    if not ok then
        vim.notify('Failed to run black: ' .. tostring(result), vim.log.levels.ERROR)
        return
    end

    vim.cmd.edit()
    -- black reports what it did (or the error) on stderr
    print(vim.trim(result.stderr .. result.stdout))
end

function M.move_to_column(column)
    -- Get the current column
    local curr = vim.api.nvim_win_get_cursor(0)[2]

    -- Make sure the target column is valid
    if column == nil or column % 1 ~= 0 then
        column = 80
    end

    local insertion_count = (column - curr) - 1

    -- Make sure we aren't already past the target column
    if insertion_count <= 0 then
        print('Target column is less than or equal to current column')
        return
    end

    local insertion_string = ''
    for i = 1, insertion_count, 1 do
        insertion_string = insertion_string .. ' '
    end

    local line = vim.api.nvim_get_current_line()
    local nline = line:sub(0, curr) .. insertion_string .. line:sub(curr + 1)
    vim.api.nvim_set_current_line(nline)
end

-- Closes every tab page to the right of the current one. Each 'tabclose' is
-- guarded so the loop cannot spin forever: it stops if the command fails (for
-- example an autocmd that throws) or if the tab count does not actually
-- decrease.
function M.close_tabs_to_right()
    local cur = vim.fn.tabpagenr()
    while cur < vim.fn.tabpagenr('$') do
        local before = vim.fn.tabpagenr('$')
        local ok, err = pcall(vim.cmd, 'tabclose ' .. (cur + 1))
        if not ok then
            Log.warn('close_tabs_to_right: tabclose failed: ' .. (tostring(err):gsub('%s+', ' ')))
            break
        end
        if vim.fn.tabpagenr('$') >= before then
            -- A 'tabclose' that reports success without reducing the tab count
            -- (e.g. an autocmd opening a new tab) would otherwise loop forever.
            Log.warn('close_tabs_to_right: no progress closing tab ' .. (cur + 1))
            break
        end
    end
end

function M.is_wsl()
    local x = os.getenv('WSL_DISTRO_NAME')
    return type(x) == 'string' and string.len(x) > 0
end

-- Returns the current file path and line number underneath the cursor
-- formatted as:
-- path/to/file.cpp:42
function M.get_file_and_line()
    return vim.fn.expand('%') .. ':' .. vim.fn.line('.')
end

function M.copy_file_and_line()
    local file_and_line = M.get_file_and_line()
    vim.fn.setreg('+', file_and_line)
end

-- Copies the given range of lines to the clipboard formatted as a Markdown
-- code block, prefixed with the file path and line range.
function M.copy_code_snippet(start_line, end_line)
    local filename = vim.fn.expand('%')

    local lines = vim.fn.getline(start_line, end_line)

    local header = filename .. ':' .. start_line .. '-' .. end_line
    local formatted_text = header .. '\n```\n' .. table.concat(lines, '\n') .. '\n```\n'

    vim.fn.setreg('+', formatted_text)
    vim.fn.setreg('*', formatted_text)

    print('Snippet copied to clipboard!')
end

return M
