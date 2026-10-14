--[[

An fzf picker for tab pages. Each tab is one line:

    /abs/path/to/focused.json<Tab>42<Tab>3 * foo.json, bar.json

The first two tab-delimited fields are hidden (--with-nth 3..) and only feed
fzf.vim's preview of the tab's focused window, scrolled to its cursor line.
The visible part is the tab number, a * on the current tab, and every file
open in the tab, so any of them (or the number) can be typed to find it.

]]

local vim = vim

local M = {}

local function format_tab(tab, current)
    local names = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
        if name ~= '' then
            table.insert(names, vim.fn.fnamemodify(name, ':~:.'))
        end
    end

    local focused_win = vim.api.nvim_tabpage_get_win(tab)
    local focused = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(focused_win))
    local lnum = vim.api.nvim_win_get_cursor(focused_win)[1]

    return string.format(
        '%s\t%d\t%d %s %s',
        focused,
        lnum,
        vim.api.nvim_tabpage_get_number(tab),
        tab == current and '*' or ' ',
        #names > 0 and table.concat(names, ', ') or '[No Name]'
    )
end

local function jump(line)
    local nr = line:match('^[^\t]*\t%d+\t(%d+) ')
    if nr ~= nil then
        vim.cmd.tabnext(tonumber(nr))
    end
end

function M.pick()
    local current = vim.api.nvim_get_current_tabpage()
    local source = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        table.insert(source, format_tab(tab, current))
    end

    local spec = {
        source = source,
        placeholder = '{1}:{2}',
        options = {
            '--delimiter',
            '\t',
            '--with-nth',
            '3..',
            '--preview-window',
            '+{2}-/2',
            '--tiebreak',
            'index',
            '--prompt',
            'Tabs> ',
        },
    }
    spec = vim.fn['fzf#vim#with_preview'](spec)
    -- Set the sink before fzf#wrap, which only installs its own file-opening
    -- sink (and --expect keys for it) when the spec has none.
    spec.sink = jump
    spec = vim.fn['fzf#wrap']('tabs', spec)

    vim.fn['fzf#run'](spec)
end

return M
