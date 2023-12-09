function format_current_python_file()
    local command = "black " .. vim.api.nvim_buf_get_name(0) .. " 2>&1"
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    vim.cmd "edit"
    print(result)
end

function print_current_filetype()
    print(vim.bo.filetype)
end

function is_int(n)
  return (type(n) == "number") and (math.floor(n) == n)
end

function move_to_column(column)
    -- Get the current column
    local curr = vim.api.nvim_win_get_cursor(0)[2]

    -- Make sure the target column is valid
    if column == nil or not is_int(column) then
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
