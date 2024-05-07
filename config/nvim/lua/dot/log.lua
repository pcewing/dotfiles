local vim = vim

local M = {
    path = nil,
    level = nil,
    levels = {
        off   = { display = "[off]  ", value = 0, vim_level = vim.log.levels.OFF   },
        trace = { display = "[trace]", value = 1, vim_level = vim.log.levels.TRACE },
        debug = { display = "[debug]", value = 2, vim_level = vim.log.levels.DEBUG },
        info  = { display = "[info] ", value = 3, vim_level = vim.log.levels.INFO  },
        warn  = { display = "[warn] ", value = 4, vim_level = vim.log.levels.WARN  },
        error = { display = "[error]", value = 5, vim_level = vim.log.levels.ERROR },
    }
}

function M._format(level, msg)
    -- TODO: Add a timestamp
    return level.display .. " " .. msg .. "\n"
end

function M._log(level, msg)
    if M.path == nil or M.level == nil or level.value < M.level.value then
        return
    end

    local file = io.open(M.path, "a")
    io.output(file)
    io.write(M._format(level, msg))
    io.close(file)
end

function M.trace(msg) M._log(M.levels.trace, msg) end
function M.debug(msg) M._log(M.levels.debug, msg) end
function M.info(msg)  M._log(M.levels.info,  msg) end
function M.warn(msg)  M._log(M.levels.warn,  msg) end
function M.error(msg) M._log(M.levels.error, msg) end

function M.init(level, path)
    M.level = level
    M.path = path
end

return M
