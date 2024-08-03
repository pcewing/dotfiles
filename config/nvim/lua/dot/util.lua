local vim = vim

local Log = require('dot.log')

local M = {}

function M.is_windows()
    -- TODO: Confirm this is right; only checked it on Linux
    return vim.loop.os_uname().sysname == "Windows"
end

function M.is_linux()
    return vim.loop.os_uname().sysname == "Linux"
end

function M.path_sep()
    if M.is_windows() then return "\\" else return "/" end
end

function M.str_join(sep, ...)
    return table.concat({...}, sep)
end

function M.path_join(...)
    return M.str_join(M.path_sep(), ...)
end

function M.tmp_dir()
    return M.path_join(os.getenv('HOME'), '.tmp', 'nvim')
end

function M.data_dir()
    return vim.fn.stdpath('data')
end

function M.config_dir()
    return vim.fn.stdpath('config')
end

function M.config_path()
    return M.path_join(M.config_dir(), "init.lua")
end

function M.is_int(n)
  return (type(n) == "number") and (math.floor(n) == n)
end

function M.is_string(n)
  return type(n) == "string"
end

function M.reload_config(config)
    if config == nil or not M.is_string(config) or string.len(config) == 0 then
        config = M.config_path()
    end

    vim.cmd("luafile " .. config)
end

function M.format_current_python_file()
    local command = "black " .. vim.api.nvim_buf_get_name(0) .. " 2>&1"
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    vim.cmd "edit"
    print(result)
end

function M.print_current_filetype()
    print(vim.bo.filetype)
end

function M.move_to_column(column)
    -- Get the current column
    local curr = vim.api.nvim_win_get_cursor(0)[2]

    -- Make sure the target column is valid
    if column == nil or not M.is_int(column) then
        column = 80
    end

    local insertion_count = (column - curr) - 1

    -- Make sure we aren't already past the target column
    if insertion_count <= 0 then
        print("Target column is less than or equal to current column")
        return
    end

    local insertion_string = ""
    for i = 1,insertion_count,1
    do
        insertion_string = insertion_string .. " "
    end

    local line = vim.api.nvim_get_current_line()
    local nline = line:sub(0, curr) .. insertion_string .. line:sub(curr + 1)
    vim.api.nvim_set_current_line(nline)
end

function M.close_tabs_to_right()
    local cur = vim.fn.tabpagenr()
    while cur < vim.fn.tabpagenr('$') do
        vim.cmd('tabclose ' .. (cur + 1))
    end
end

function M.is_wsl()
    local x = os.getenv("WSL_DISTRO_NAME")
    return type(x) == "string" and string.len(x) > 0
end

function M.directory_exists(path)
    return vim.fn.isdirectory(path) ~= 0
end

function M.file_exists(path)
   local f = io.open(path, "r")
   if f ~= nil then
       io.close(f)
       return true
   else
       return false
   end
end

-- Returns the current file path and line number underneath the cursor
-- formatted as:
-- path/to/file.cpp:42
function M.get_file_and_line()
    return M.str_join(':', vim.fn.expand('%'), vim.fn.line('.'))
end

function M.copy_file_and_line()
    local file_and_line = M.get_file_and_line()
    vim.fn.setreg('+', file_and_line)
end

--[[
  Truncates a string from the center if it exceeds the specified maximum
  length.

  The string is truncated by removing characters from the middle and replacing
  them with two periods ('..') if the length of the input string exceeds the
  specified maximum length. The resulting truncated string will have a total
  length not exceeding the max_length parameter.

  Example:
    truncate_center("VeryLongFileName.cpp", 12) => "VeryL..e.cpp"

  Parameters:
    str (string): The input string to be truncated.
    max_length (number): The maximum allowed length for the resulting string.

  Returns:
    string: The possibly truncated string.
]]
function M.truncate_center(str, max_length)
    local length = #str
    if length <= max_length then
        return str
    else
        local part_length = math.floor((max_length - 2) / 2)
        return str:sub(1, part_length) .. ".." .. str:sub(length - part_length + 1, length)
    end
end

-- Returns whether or not a buffer contains unsaved changes
function M.is_buffer_modified(buffer_index)
    return vim.fn.getbufvar(buffer_index, '&modified') == 1
end

return M
