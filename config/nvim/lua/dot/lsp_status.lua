--[[

An "LSP" indicator in the statusline whose color summarizes the language
servers for the current buffer:

    green   every server expected for the filetype is attached and running
    yellow  loading: a server is still starting
    orange  degraded: a server has reported a warning or error message, or
            only some of the expected servers are running
    red     servers are expected for the filetype but none is running, e.g.
            the executable is not on PATH or the server exited
    gray    no server is configured for the filetype

Details are shown in a popup by:

    - clicking "LSP"
    - hovering the mouse over "LSP" (when enabled; see M.setup)
    - :DisplayLSPStatus (press it again to focus the popup; q or <Esc> closes it)

The expected servers are the ones passed to M.setup, matched against the
filetypes in their vim.lsp.config(). A server is expected even when its
executable is missing, which is what lets this report it.

]]

local vim = vim

local M = {}

-- How long after a buffer gets its filetype that a missing server is shown as
-- "starting" rather than as an error
local grace_ms = 2000

-- The most recent window/showMessage warnings and errors kept per client
local max_messages = 5

local state = {
    -- name -> { executable = string }, from M.setup
    servers = {},
    -- bufnr -> vim.uv.now() when the buffer last got a filetype
    filetype_set_at = {},
    -- client name -> { code, signal } for the last exit of a client with that
    -- name, cleared when one attaches again
    exits = {},
    -- client id -> list of { type, message }
    messages = {},
    -- The popup's window, and whether it was opened by hovering
    popup_win = nil,
    popup_is_hover = false,
}

local levels = {
    -- The Diagnostic* defaults are pale colors that base16 doesn't override,
    -- so use the theme's own colors when there are some: base0B green, base0A
    -- yellow, base09 orange, and base08 red
    ok = { group = 'DotLspStatusOk', source = 'DiagnosticOk', base16 = '0B', icon = '✓', label = 'connected' },
    loading = {
        group = 'DotLspStatusLoading',
        source = 'DiagnosticWarn',
        base16 = '0A',
        icon = '…',
        label = 'starting',
    },
    warn = { group = 'DotLspStatusWarn', source = 'DiagnosticWarn', base16 = '09', icon = '!', label = 'degraded' },
    error = {
        group = 'DotLspStatusError',
        source = 'DiagnosticError',
        base16 = '08',
        icon = '✗',
        label = 'not running',
    },
    none = { group = 'DotLspStatusNone', source = 'Comment', icon = '-', label = 'no server configured' },
}

-- Returns the foreground for a level: the base16 palette color named by
-- level.base16 when a base16 colorscheme is loaded, otherwise the color of
-- the level's source group
local function level_colors(level)
    local gui = level.base16 and vim.g['base16_gui' .. level.base16]
    if gui then
        local cterm = vim.g['base16_cterm' .. level.base16]
        return { fg = '#' .. gui, ctermfg = cterm and tonumber(cterm) }
    end
    local source = vim.api.nvim_get_hl(0, { name = level.source, link = false })
    return { fg = source.fg, ctermfg = source.ctermfg }
end

-- Each level has a statusline group (its color on StatusLine's background) and
-- a popup group (just the color). They need recomputing whenever the
-- colorscheme changes.
local function set_highlights()
    local statusline = vim.api.nvim_get_hl(0, { name = 'StatusLine', link = false })
    for _, level in pairs(levels) do
        local colors = level_colors(level)
        vim.api.nvim_set_hl(0, level.group, {
            fg = colors.fg,
            ctermfg = colors.ctermfg,
            bg = statusline.bg,
            ctermbg = statusline.ctermbg,
        })
        vim.api.nvim_set_hl(0, level.group .. 'Popup', colors)
    end
end

local function redraw()
    vim.cmd.redrawstatus()
end

local function short_path(path)
    return path and vim.fn.fnamemodify(path, ':~') or nil
end

-- Clients attached to buf. _uninitialized includes clients that are still
-- waiting on the server's initialize response, which are otherwise left out.
local function attached_clients(buf)
    return vim.lsp.get_clients({ bufnr = buf, _uninitialized = true })
end

local function client_entry(client)
    local messages = state.messages[client.id] or {}
    local level, detail
    if not client.initialized then
        level, detail = 'loading', 'starting…'
    else
        level = #messages > 0 and 'warn' or 'ok'
        detail = 'running'
        if client.root_dir then
            detail = detail .. ' · root ' .. short_path(client.root_dir)
        end
    end
    return { name = client.name, level = level, working = client.initialized, detail = detail, messages = messages }
end

local function missing_entry(name, buf)
    local server = state.servers[name]
    if vim.fn.executable(server.executable) == 0 then
        return { name = name, level = 'error', detail = '`' .. server.executable .. '` command not found on PATH' }
    end

    local exit = state.exits[name]
    if exit then
        local detail
        if exit.signal ~= 0 then
            detail = 'server was killed (signal ' .. exit.signal .. ')'
        elseif exit.code ~= 0 then
            detail = 'server exited with code ' .. exit.code
        else
            detail = 'server was stopped (e.g. :lsp stop)'
        end
        return { name = name, level = 'error', detail = detail }
    end

    local set_at = state.filetype_set_at[buf]
    if set_at and vim.uv.now() - set_at < grace_ms then
        return { name = name, level = 'loading', detail = 'starting…' }
    end

    return {
        name = name,
        level = 'error',
        detail = 'not attached: no project root was found or the server failed to start (see :checkhealth vim.lsp)',
    }
end

-- Returns the overall level and one entry per expected or attached server
local function buffer_status(buf)
    local filetype = vim.bo[buf].filetype
    local entries = {}
    local seen = {}

    for _, client in ipairs(attached_clients(buf)) do
        table.insert(entries, client_entry(client))
        seen[client.name] = true
    end

    -- Servers only start in normal file buffers
    if vim.bo[buf].buftype == '' and filetype ~= '' then
        local names = vim.tbl_keys(state.servers)
        table.sort(names)
        for _, name in ipairs(names) do
            local config = vim.lsp.config[name]
            if not seen[name] and config and vim.tbl_contains(config.filetypes or {}, filetype) then
                table.insert(entries, missing_entry(name, buf))
            end
        end
    end

    if #entries == 0 then
        return 'none', entries
    end

    local working = 0
    local counts = { ok = 0, loading = 0, warn = 0, error = 0 }
    for _, entry in ipairs(entries) do
        if entry.working then
            working = working + 1
        end
        counts[entry.level] = counts[entry.level] + 1
    end

    -- A failed server only makes the buffer "not running" when nothing else
    -- is running or starting; otherwise it's degraded, or still loading until
    -- the starting servers settle
    if counts.warn > 0 or (counts.error > 0 and working > 0) then
        return 'warn', entries
    elseif counts.loading > 0 then
        return 'loading', entries
    elseif counts.error > 0 then
        return 'error', entries
    end
    return 'ok', entries
end

-- The statusline item. With a global statusline, g:statusline_winid is the
-- current window.
function M.statusline()
    local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
    local level = buffer_status(buf)
    return '%#' .. levels[level].group .. '#%@v:lua.DotLspStatusClick@LSP%X%* '
end

-- Returns the 0-based screen column where "LSP" is drawn in the global
-- statusline, or nil when it isn't shown (e.g. after a configuration error
-- replaced the statusline)
local function indicator_column()
    local result = vim.api.nvim_eval_statusline(vim.o.statusline, {
        winid = vim.api.nvim_get_current_win(),
        highlights = true,
    })
    for _, hl in ipairs(result.highlights) do
        local groups = hl.groups or { hl.group }
        if vim.startswith(groups[#groups] or '', 'DotLspStatus') then
            return vim.fn.strdisplaywidth(result.str:sub(1, hl.start))
        end
    end
    return nil
end

local function close_popup()
    if state.popup_win and vim.api.nvim_win_is_valid(state.popup_win) then
        vim.api.nvim_win_close(state.popup_win, true)
    end
    state.popup_win = nil
end

local function popup_lines(buf)
    local level, entries = buffer_status(buf)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')
    local filetype = vim.bo[buf].filetype

    -- Each line is a list of { text, highlight group } chunks
    local lines = {
        {
            { 'LSP: ', 'Title' },
            { levels[level].label, levels[level].group .. 'Popup' },
            {
                '  '
                    .. (name ~= '' and name or '[No Name]')
                    .. ' ('
                    .. (filetype ~= '' and filetype or 'no filetype')
                    .. ')',
                'Comment',
            },
        },
    }

    if #entries == 0 then
        table.insert(lines, { { 'No language server is configured for this filetype', 'Comment' } })
    end

    local width = 0
    for _, entry in ipairs(entries) do
        width = math.max(width, #entry.name)
    end

    for _, entry in ipairs(entries) do
        local level_info = levels[entry.level]
        table.insert(lines, {
            { level_info.icon .. ' ', level_info.group .. 'Popup' },
            { entry.name .. string.rep(' ', width - #entry.name + 2), 'Identifier' },
            { entry.detail, entry.level == 'ok' and 'Normal' or level_info.group .. 'Popup' },
        })
        for _, message in ipairs(entry.messages or {}) do
            local kind = message.type == vim.lsp.protocol.MessageType.Error and 'error' or 'warning'
            -- Messages can be multi-line; show the first line only
            local text = vim.split(message.message, '\n')[1]
            table.insert(lines, {
                {
                    string.rep(' ', width + 4) .. kind .. ': ' .. text,
                    levels[kind == 'error' and 'error' or 'warn'].group .. 'Popup',
                },
            })
        end
    end

    return lines
end

-- Opens the popup just above the "LSP" item (or at the right edge when the
-- item isn't shown)
local function open_popup(is_hover)
    close_popup()

    local lines = popup_lines(vim.api.nvim_get_current_buf())
    local text, width = {}, 0
    for i, chunks in ipairs(lines) do
        local line = ''
        for _, chunk in ipairs(chunks) do
            line = line .. chunk[1]
        end
        text[i] = line
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    width = math.min(width, vim.o.columns - 4)

    local popup_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, text)
    local ns = vim.api.nvim_create_namespace('dot_lsp_status')
    for i, chunks in ipairs(lines) do
        local col = 0
        for _, chunk in ipairs(chunks) do
            vim.api.nvim_buf_set_extmark(popup_buf, ns, i - 1, col, { end_col = col + #chunk[1], hl_group = chunk[2] })
            col = col + #chunk[1]
        end
    end
    vim.bo[popup_buf].modifiable = false
    vim.bo[popup_buf].bufhidden = 'wipe'

    -- Keep the border on screen: the window is width + 2 columns wide
    local col = indicator_column() or vim.o.columns
    col = math.max(0, math.min(col, vim.o.columns - width - 2))

    state.popup_win = vim.api.nvim_open_win(popup_buf, false, {
        relative = 'editor',
        -- The bottom edge sits on the statusline's row, so the window ends
        -- just above it
        anchor = 'SW',
        row = vim.o.lines - vim.o.cmdheight - 1,
        col = col,
        width = width,
        height = #text,
        style = 'minimal',
        border = 'rounded',
        focusable = true,
        noautocmd = true,
    })
    vim.wo[state.popup_win].wrap = false
    state.popup_is_hover = is_hover

    for _, lhs in ipairs({ 'q', '<Esc>' }) do
        vim.keymap.set('n', lhs, close_popup, { buffer = popup_buf, nowait = true })
    end
end

local function popup_is_open()
    return state.popup_win ~= nil and vim.api.nvim_win_is_valid(state.popup_win)
end

-- :DisplayLSPStatus. Like K, running it again while the popup is open moves
-- into the popup.
function M.display()
    if popup_is_open() then
        vim.api.nvim_set_current_win(state.popup_win)
    else
        open_popup(false)
    end
end

-- The statusline click handler (see %@ in :help 'statusline'). Clicking again
-- closes the popup.
function _G.DotLspStatusClick()
    if popup_is_open() and not state.popup_is_hover then
        close_popup()
    else
        open_popup(false)
    end
end

-- <MouseMove> handler: opens the popup while the mouse is over "LSP" and closes
-- a hover-opened popup once it leaves
local function on_mouse_move()
    local pos = vim.fn.getmousepos()
    local over = false
    -- Only the global statusline is supported. Everything but the row check
    -- is skipped for the rest of the screen, as this runs on every mouse move.
    if vim.o.laststatus == 3 and pos.screenrow == vim.o.lines - vim.o.cmdheight then
        local col = indicator_column()
        over = col ~= nil and pos.screencol > col and pos.screencol <= col + 3
    end

    if over and not popup_is_open() then
        open_popup(true)
    elseif not over and popup_is_open() and state.popup_is_hover then
        close_popup()
    end
end

local function on_show_message(err, result, ctx)
    local types = vim.lsp.protocol.MessageType
    if result and (result.type == types.Error or result.type == types.Warning) then
        local messages = state.messages[ctx.client_id] or {}
        table.insert(messages, { type = result.type, message = result.message })
        if #messages > max_messages then
            table.remove(messages, 1)
        end
        state.messages[ctx.client_id] = messages
        vim.schedule(redraw)
    end
    return vim.lsp.handlers['window/showMessage'](err, result, ctx)
end

-- servers: name -> { executable = string }, the servers expected to run for
-- their filetypes. Call before vim.lsp.enable() so the exit and message hooks
-- are part of each server's config.
--
-- opts.hover: show the popup when the mouse hovers over "LSP". This turns on
-- 'mousemoveevent', which the help warns can abort a pending mapping when the
-- mouse moves. Clicking works either way.
function M.setup(servers, opts)
    opts = opts or {}
    state.servers = servers

    for name, _ in pairs(servers) do
        vim.lsp.config(name, {
            -- Each server gets its own handler (instead of replacing the
            -- global one) so a config reload can't wrap it twice
            handlers = { ['window/showMessage'] = on_show_message },
            on_exit = function(code, signal, client_id)
                state.messages[client_id] = nil
                state.exits[name] = { code = code, signal = signal }
                vim.schedule(redraw)
            end,
        })
    end

    -- Insert the item after the default statusline's left/right split (%=), so
    -- the rest of the default (diagnostics, LSP progress, ruler) is kept
    local default = vim.api.nvim_get_option_info2('statusline', {}).default
    vim.o.statusline = default:gsub('%%=', "%%=%%{%% v:lua.require('dot.lsp_status').statusline() %%}", 1)

    local group = vim.api.nvim_create_augroup('dot_lsp_status', { clear = true })
    vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = set_highlights })
    set_highlights()

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(args)
            state.filetype_set_at[args.buf] = vim.uv.now()
            -- Show the error once the grace period ends if nothing attached
            vim.defer_fn(redraw, grace_ms + 50)
        end,
    })
    vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client then
                state.exits[client.name] = nil
            end
            redraw()
        end,
    })
    vim.api.nvim_create_autocmd('LspDetach', { group = group, callback = vim.schedule_wrap(redraw) })
    vim.api.nvim_create_autocmd('BufWipeout', {
        group = group,
        callback = function(args)
            state.filetype_set_at[args.buf] = nil
        end,
    })
    -- Close the popup when moving on, as with K
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'BufEnter' }, {
        group = group,
        callback = function()
            if popup_is_open() and vim.api.nvim_get_current_win() ~= state.popup_win then
                close_popup()
            end
        end,
    })

    vim.api.nvim_create_user_command('DisplayLSPStatus', M.display, { desc = 'Show LSP status for the buffer' })

    if opts.hover then
        vim.o.mousemoveevent = true
        -- Not mapped in insert mode, where a mapping firing on every mouse
        -- move could interfere with typing and the completion menu
        vim.keymap.set({ 'n', 'v' }, '<MouseMove>', on_mouse_move, { desc = 'LSP status hover' })
    end
end

return M
