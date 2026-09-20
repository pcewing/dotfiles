-- Linux-specific configuration. Anything that only applies when Neovim runs on
-- a Linux host (but not in WSL, which has its own module) belongs in here.
--
-- Neovim has no built-in system clipboard. The 'clipboard' option in
-- dot.settings delegates the unnamed register to an external tool that Neovim
-- has to discover in the environment it inherits, and Neovim will not fall back
-- to OSC 52 on its own whenever 'clipboard' is non-empty (see
-- runtime/autoload/provider/clipboard.vim). That means a session where no
-- X11/Wayland tool is reachable (SSH, a server host, tmux started from a
-- non-graphical context) silently copies nothing at all. Resolve the provider
-- ourselves so the OSC 52 fallback is always available.

local Log  = require('dot.log')
local Util = require('dot.util')

local M = {}

-- Ordered the same way Neovim orders its own auto-detection (Wayland before
-- X11, tmux before OSC 52). The return value is the string form of
-- `g:clipboard`, which selects one of Neovim's builtin providers.
function M._resolve_clipboard_provider()
    -- Both halves of wl-clipboard are needed: Neovim registers a copy and a
    -- paste command together, matching its own auto-detection.
    if Util.env_is_set("WAYLAND_DISPLAY")
        and vim.fn.executable("wl-copy") == 1
        and vim.fn.executable("wl-paste") == 1 then
        return "wl-copy"
    end

    if Util.env_is_set("DISPLAY") then
        if vim.fn.executable("xsel") == 1 then
            return "xsel"
        end
        if vim.fn.executable("xclip") == 1 then
            return "xclip"
        end
    end

    -- Inside tmux the tmux provider is better than OSC 52 because tmux
    -- forwards the selection to the outer terminal itself.
    if Util.env_is_set("TMUX") and vim.fn.executable("tmux") == 1 then
        return "tmux"
    end

    -- Last resort for remote/headless sessions. Setting g:clipboard explicitly
    -- is what opts us into this; Neovim will not choose it while 'clipboard' is
    -- set.
    return "osc52"
end

function M._clipboard()
    local provider = M._resolve_clipboard_provider()

    vim.g.clipboard = provider

    Log.debug("Using " .. provider .. " for the system clipboard")
end

function M.init()
    M._clipboard()
end

return M
