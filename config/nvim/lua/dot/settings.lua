local Util = require('dot.util')
local Log = require('dot.log')

local M = {}

-- Base settings
function M._base()
    vim.opt.number = true                             -- Show line numbers
    vim.opt.backspace = { "indent", "eol", "start" }  -- Make backspace behave as expected in insert mode
    vim.opt.history = 1000                            -- Increase :cmdline history
    vim.opt.showcmd = true                            -- Show incomplete commands
    vim.opt.showmode = true                           -- Show current mode
    vim.opt.guicursor = 'a:blinkon0'                  -- Disable cursor blink
    vim.opt.visualbell = true                         -- No sounds
    vim.opt.autoread = true                           -- Reload files changed outside vim
    vim.opt.autowrite = true                          -- Write the file on :make
    vim.opt.hidden = false                            -- Hide buffer instead of closing it
    vim.opt.splitright = true                         -- When splitting vertically, the new pane should be on the right
    vim.opt.splitbelow = true                         -- When splitting horizontally, the new pane should be on the bottom
    vim.opt.ruler = true                              -- Show the line & column number at cursor
    vim.opt.clipboard = "unnamed,unnamedplus"         -- Use system clipboard if possible
    vim.opt.cursorline = true                         -- Add a visual indicator to the line the cursor is on
    vim.opt.joinspaces = false                        -- Don't insert an extra space after periods when joining lines

    -- Use global status line
    vim.opt.laststatus = 3
end

-- Indentation settings
function M._indentation()
    vim.opt.autoindent  = true
    vim.opt.smartindent = true
    vim.opt.smarttab    = true
    vim.opt.shiftwidth  = 4
    vim.opt.softtabstop = 4
    vim.opt.tabstop     = 4
    vim.opt.expandtab   = true

    -- Disable smart indent in markdown files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            vim.opt_local.smartindent = false
        end
    })
end

function M._directories()
    -- Add a double slash on the path which instructs Neovim to create a unique
    -- directory for each editing session
    -- TODO: Should this be \\ on windows?
    local dir = Util.tmp_dir() .. "//"

    Log.debug('Setting backup dir to ' .. dir)

    -- Backup and swap directories; the double slashes are important here
    vim.opt.backupdir = { dir, "." }
    vim.opt.directory = { dir, "." }
end

function M._get_tab_info(i)
    -- Check whether or not the tab is selected
    local is_selected = false
    if i == vim.fn.tabpagenr() then
        is_selected = true
    end

    local buflist = vim.fn.tabpagebuflist(i)
    local winnr = vim.fn.tabpagewinnr(i)

    -- The title is the name of the file currently open in the buffer focused
    -- within the tab. If it doesn't have one because it's an unsaved buffer,
    -- fall back to UNSAVED
    local title = vim.fn.fnamemodify(vim.fn.bufname(buflist[winnr]), ":t")
    if #title == 0 then
        title = "UNSAVED"
    end

    -- Check if any buffers open in the tab are modified and need to be save
    local is_modified = false
    for _, i in ipairs(buflist) do
        if Util.is_buffer_modified(i) then
            Log.debug("buffer " .. i .. " is modified")
            is_modified = true
            break
        end
    end

    return {
        title = title,
        index = i,
        is_modified = is_modified,
        is_selected = is_selected
    }
end

function M._format_tabline_tab(tab)
    local s = ""

    -- Format the modified indicator
    s = s .. (tab["is_modified"] and "+" or " ")

    -- Format the tab index
    s = s .. "[" .. tab["index"] .. "] "

    -- Format the tab title
    s = s .. tab["title"]

    return s
end

function M._format_tabline_no_truncation(tabs)
    local s = ""
    for i, tab in pairs(tabs) do
        -- Separate tabs with a space
        if i > 1 then
            s = s .. " "
        end
        -- Set the tab metadata
        s = s .. (tab["is_selected"] and "%#TabLineSel#" or "%#TabLine#")
        s = s .. "%" .. tab["index"] .. "T"

        s = s .. M._format_tabline_tab(tab)
    end
    return s .. '%#TabLineFill#%T'
end

-- The "Basic" truncation strategy is to hide all of the tabs that don't fit on
-- the tabline and put an indicator on the right of how many more tabs there
-- are. I Personallly like this better than squishing each tab down. I'd rather
-- the first N tabs be readable and just hide the ones that don't fit than make
-- them all less readable.
function M._format_tabline_basic_truncation(tabs, truncation)
    -- TODO: We could merge this loop with the one below and do this in one
    -- pass but I'm too lazy right now
    local tab_contents = {}
    for i, tab in pairs(tabs) do
        local meta = (tab["is_selected"] and "%#TabLineSel#" or "%#TabLine#")
        meta = meta .. "%" .. tab["index"] .. "T"

        local label = M._format_tabline_tab(tab)

        tab_contents[i] = {
            meta = meta,
            label = label
        }
    end

    local suffix_base_len = #" ... (x more)"
    local current_length = 0
    local truncate_index = 0
    for i, tab_content in pairs(tab_contents) do
        -- First, check if we can even fit the truncation suffix. It could be
        -- longer than the tab label if the file in the tab has a very short
        -- name. If this won't fit, then we actually need to start truncating
        -- at the previous tab
        local remaining_tabs = (#tabs - i) + 1
        local suffix_len = suffix_base_len + math.floor(remaining_tabs / 10)
        if (current_length + suffix_len) > truncation["max_length"] then
            truncate_index = math.max(0, i - 1)
            break
        end

        -- Separate tabs with a space
        local separator = ""
        if i > 1 then
            separator = " "
        end

        local tab_len = #tab_content["label"] + #separator

        -- If appending this label would exceed the max length, start
        -- truncating at this tab
        if (current_length + tab_len) > truncation["max_length"] then
            truncate_index = i
            break
        end

        current_length = current_length + tab_len
    end

    -- Now that we know where to start truncating, format the tabline
    local s = ""
    for i, tab_content in pairs(tab_contents) do
        if i >= truncate_index then
            break
        end
        if i > 1 then
            s = s .. " "
        end
        s = s .. tab_content["meta"] .. tab_content["label"]
    end

    -- Align the truncation suffix to the right
    s = s .. "%="

    -- Fill any extra space and disassociate the following text from the last tab
    s = s .. "%#TabLineFill#%T"

    -- Append the truncation suffix
    local truncated_tabs = (#tabs - truncate_index) + 1
    s = s .. "... (" .. tostring(truncated_tabs) .. " more)"

    return s
end

function M._format_tabline(tabs, truncation)
    if truncation["strategy"] == "Basic" then
        return M._format_tabline_basic_truncation(tabs, truncation)
    else
        return M._format_tabline_no_truncation(tabs)
    end
end

-- Tabline generation is done in two steps. The first step collects all of the
-- tab information and the second step formats the tabline. The reason is that
-- we need to be able to check the total length and truncate appropriately.
-- That's harder to do when the string contains characters that are actually
-- printed, like the `%#TabLine#` tokens. So instead, we need to gather all of
-- the desired tab labels, sum their lengths, choose a truncation strategy, and
-- then format everything using that strategy.
function M._generate_tabline()
    -- Get all of the tab information
    local tabs = {}
    for i = 1, vim.fn.tabpagenr('$') do
        tabs[i] = M._get_tab_info(i)
    end

    -- The length of the tab label prefix (I.E. "+[1] "), which can vary if the
    -- tab index is multiple digits. Ignoring the case of >100 tabs; I never
    -- use that many and there would be no good way to format that anyways
    local prefix_length = #tabs >= 10 and 6 or 5

    local total_length = 0
    for _, tab in ipairs(tabs) do
        local title_len = #tab["title"]
        local tab_len = title_len + prefix_length
        total_length = total_length + tab_len
    end

    -- We separate tabs with a space so account for that as well
    total_length = total_length + #tabs - 1

    local truncation = {
        strategy = "None",
        total_length = total_length,
        max_length = vim.o.columns,
        amount = 0,
        amount_per_tab = 0,
    }

    -- Handle truncating if the tabline is too long
    if total_length > truncation["max_length"] then
        truncation["strategy"] = "Basic"
        truncation["amount"] = truncation["total_length"] - truncation["max_length"]
        truncation["amount_per_tab"] = truncation["amount"] - #tabs
    end

    return M._format_tabline(tabs, truncation)
end

function M._tab_line()
    vim.o.tabline = "%!v:lua.require'dot.settings'._generate_tabline()"
end

function M.init()
    M._base()
    M._indentation()
    M._directories()
    M._tab_line()
end

return M
