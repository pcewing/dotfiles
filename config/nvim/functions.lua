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
