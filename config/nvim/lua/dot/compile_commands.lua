--[[

An fzf picker for choosing which compile_commands.json clangd uses, for repos
that generate one per project outside the source tree (e.g. a premake build
under build/<app>/windows/).

It lists every compile_commands.json below the current directory, including
ones in gitignored build directories. Selecting one restarts clangd with
--compile-commands-dir pointing at its directory. The flag takes precedence
over a CompilationDatabase set in a .clangd file, and lasts until Neovim exits.

]]

local vim = vim

local M = {}

local file_name = 'compile_commands.json'

local function source()
    if vim.fn.executable('rg') == 1 then
        -- --no-ignore because build directories are usually gitignored. The
        -- glob has no slash, so it matches the file name at any depth.
        return 'rg --files --no-ignore --glob ' .. file_name
    end

    local files = vim.fs.find(file_name, { limit = math.huge, type = 'file' })
    return vim.tbl_map(function(file)
        return vim.fn.fnamemodify(file, ':.')
    end, files)
end

-- vim.lsp.enable() starts clients from the current vim.lsp.config, but
-- ":lsp restart" reuses each running client's old config. So stop the clients,
-- wait for them to exit, and re-enable clangd, which re-runs the FileType
-- autocmd that attaches it to every loaded buffer.
local function restart_clangd()
    for _, client in ipairs(vim.lsp.get_clients({ name = 'clangd' })) do
        client:stop()
    end

    -- client:is_stopped() is true as soon as shutdown starts, but a client
    -- that hasn't exited yet would be reused by vim.lsp.enable(), so wait
    -- until they're gone.
    local stopped = vim.wait(5000, function()
        return #vim.lsp.get_clients({ name = 'clangd' }) == 0
    end)
    if not stopped then
        vim.notify('clangd did not exit; run :lsp stop clangd and reopen the file', vim.log.levels.WARN)
        return
    end

    -- lsp.lua only enables clangd when its executable is on PATH
    if vim.lsp.is_enabled('clangd') then
        vim.lsp.enable('clangd')
    end
end

local function activate(line)
    local dir = vim.fs.dirname(vim.fs.abspath(line))
    vim.lsp.config('clangd', { cmd = { 'clangd', '--compile-commands-dir=' .. dir } })
    restart_clangd()
    vim.notify('clangd: using ' .. vim.fn.fnamemodify(line, ':.'))
end

function M.pick()
    local spec = vim.fn['fzf#wrap']('compile-commands', {
        source = source(),
        sink = activate,
        window = { width = 0.6, height = 0.4 },
        options = { '--prompt', 'compile_commands.json> ' },
    })
    vim.fn['fzf#run'](spec)
end

return M
