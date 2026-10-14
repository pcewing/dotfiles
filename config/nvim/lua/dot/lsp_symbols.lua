--[[

A live fzf picker for LSP workspace symbols, similar to Telescope's
lsp_dynamic_workspace_symbols.

fzf runs with --disabled, so it does no filtering itself. Instead, every change
to the query re-runs scripts/lsp_symbols_query.lua, which connects back to this
Neovim over its RPC socket (v:servername) and calls M.query(). That sends a
"workspace/symbol" request for the query and returns one line per symbol:

    path/to/file.c:12:5: [Function] foo_init

The "file:line:" prefix lets fzf.vim's preview window show the code around each
symbol, and lets the sink jump to it.

]]

local vim = vim

local M = {}

-- The buffer the picker was opened from. While fzf is open, the current buffer
-- is fzf's terminal, which has no LSP client attached, so queries must target
-- this buffer instead.
local source_buf = nil

local this_file = debug.getinfo(1, 'S').source:sub(2)
local query_script =
    vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(this_file), '..', '..', 'scripts', 'lsp_symbols_query.lua'))

-- Called over RPC by scripts/lsp_symbols_query.lua for every query change.
function M.query(query)
    if source_buf == nil or not vim.api.nvim_buf_is_valid(source_buf) then
        return {}
    end

    local responses = vim.lsp.buf_request_sync(source_buf, 'workspace/symbol', { query = query }, 2000) or {}

    local lines = {}
    for client_id, response in pairs(responses) do
        local client = vim.lsp.get_client_by_id(client_id)
        if client ~= nil and response.result ~= nil then
            local items = vim.lsp.util.symbols_to_items(response.result, source_buf, client.offset_encoding)
            for _, item in ipairs(items) do
                table.insert(
                    lines,
                    string.format(
                        '%s:%d:%d: %s',
                        vim.fn.fnamemodify(item.filename, ':.'),
                        item.lnum,
                        item.col,
                        item.text
                    )
                )
            end
        end
    end
    return lines
end

local function jump(line)
    local file, lnum, col = line:match('^(.-):(%d+):(%d+): ')
    if file == nil then
        return
    end

    -- Add the current position to the jumplist so <C-o> returns here
    vim.cmd("normal! m'")
    vim.cmd.edit(vim.fn.fnameescape(file))
    vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
end

function M.pick()
    source_buf = vim.api.nvim_get_current_buf()

    local reload = table.concat({
        vim.fn.shellescape(vim.v.progpath),
        '--clean',
        '-l',
        vim.fn.shellescape(query_script),
        vim.fn.shellescape(vim.v.servername),
        '{q}',
    }, ' ')

    local spec = {
        -- Start empty: an empty query only returns the server's capped list of
        -- arbitrary symbols, so wait for the first keystroke instead.
        source = 'true',
        options = {
            '--disabled',
            '--prompt',
            'Symbols> ',
            '--header',
            'Type to search workspace symbols',
            '--bind',
            'change:reload:' .. reload,
        },
    }
    spec = vim.fn['fzf#vim#with_preview'](spec)
    spec = vim.fn['fzf#wrap']('lsp-workspace-symbols', spec)

    -- Set the sink after fzf#wrap, which only installs its own file-opening
    -- sink when the spec has none.
    spec['sink*'] = nil
    spec.sink = jump

    vim.fn['fzf#run'](spec)
end

return M
