local vim = vim

local Log = require('dot.log')

local M = {
    notifications = {},
}

function M.add(text)
    local location = M._get_location()
    table.insert(M.notifications, {
        filename = location['file'],
        lnum = location['line'],
        col = location['column'],
        text = text
    })
end

function M.any()
    return #M.notifications > 0
end

function M.display()
    vim.fn.setqflist(M.notifications, 'r')
end

function M._get_location()
    local info = debug.getinfo(3, "Sl")
    return {
        file = info.short_src,
        line = info.currentline,
        column = 1
    }
end

return M
