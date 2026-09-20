-- WSL-specific configuration.
--
-- The usual way to reach the Windows clipboard from WSL is win32yank.exe, which
-- the win32yank provisioner installs to /mnt/c/bin (config/env puts that on
-- PATH). Neovim does not validate the commands in a g:clipboard table, so if
-- win32yank is missing every copy raises E475 -- and because setting
-- g:clipboard disables Neovim's own fallbacks, nothing else is tried. Resolve a
-- working provider up front instead: WSLg's Wayland clipboard first, then
-- win32yank, then OSC 52.

local Log  = require('dot.log')
local Util = require('dot.util')

local M = {}

-- win32yank.exe is installed to /mnt/c/bin by the win32yank provisioner and
-- config/env adds that directory to PATH. Check PATH first so an override wins,
-- then the install location in case Neovim was started from a context that
-- never sourced config/env.
local WIN32YANK_CANDIDATES = {
    "win32yank.exe",
    "/mnt/c/bin/win32yank.exe",
}

function M._find_win32yank()
    for _, candidate in ipairs(WIN32YANK_CANDIDATES) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end

    return nil
end

function M._win32yank_clipboard(path)
    return {
        name = "win32yank-wsl",
        copy = {
            ["+"] = path .. " -i --crlf",
            ["*"] = path .. " -i --crlf",
        },
        paste = {
            ["+"] = path .. " -o --lf",
            ["*"] = path .. " -o --lf",
        },
        cache_enabled = true,
    }
end

-- The return value is assigned to g:clipboard, which accepts either the name of
-- one of Neovim's builtin providers or a table of commands.
function M._resolve_clipboard_provider()
    -- WSLg runs a Wayland compositor whose clipboard is bridged to Windows.
    if Util.env_is_set("WAYLAND_DISPLAY")
        and vim.fn.executable("wl-copy") == 1
        and vim.fn.executable("wl-paste") == 1 then
        return "wl-copy"
    end

    local win32yank = M._find_win32yank()
    if win32yank ~= nil then
        return M._win32yank_clipboard(win32yank)
    end

    -- Last resort for a shell with no WSLg and no win32yank. Without this,
    -- 'clipboard' being set means Neovim has no working provider at all.
    return "osc52"
end

function M._clipboard()
    local provider = M._resolve_clipboard_provider()

    vim.g.clipboard = provider

    if type(provider) == "table" then
        Log.debug("Using " .. provider.name .. " for the system clipboard")
    else
        Log.debug("Using " .. provider .. " for the system clipboard")
    end
end

function M.init()
    vim.env.FZF_DEFAULT_COMMAND = 'fzf_cached_wsl'

    M._clipboard()
end

return M
