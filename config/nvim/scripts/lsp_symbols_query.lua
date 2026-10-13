-- Helper for lua/dot/lsp_symbols.lua, run by fzf on every query change:
--
--     nvim --clean -l lsp_symbols_query.lua <server address> <query>
--
-- Connects to the Neovim that opened the picker and prints the matching
-- workspace symbols, one per line. The query arrives as a command-line argument,
-- so quotes or other special characters in it need no escaping. Any failure
-- prints nothing, which leaves fzf with an empty list.

local address, query = arg[1], arg[2] or ''

local ok, lines = pcall(function()
    local chan = vim.fn.sockconnect('pipe', address, { rpc = true })
    return vim.rpcrequest(chan, 'nvim_exec_lua',
        "return require('dot.lsp_symbols').query(...)", { query })
end)

if ok and #lines > 0 then
    io.write(table.concat(lines, '\n'), '\n')
end
