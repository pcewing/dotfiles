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
-- X11, tmux before OSC 52), except that a Wayland session deliberately uses the
-- X11 clipboard rather than wl-clipboard. See _resolve_clipboard_provider. The
-- return value is the string form of `g:clipboard`, which selects one of
-- Neovim's builtin providers.
function M._resolve_clipboard_provider()
    -- On Wayland we intentionally do NOT use wl-clipboard, even though it is
    -- the "native" provider. Wayland gives a client no way to take ownership of
    -- a selection without mapping a surface and being handed keyboard focus
    -- (GNOME implements no data-control protocol), so `wl-copy` has to steal
    -- focus with a throwaway window on every single copy. GNOME Shell reacts by
    -- re-allocating its panel app menu and the Ubuntu Dock, and with netrw
    -- focused -- which is exactly where vim-vinegar lands you, because it forces
    -- netrw_banner=0 -- it gets stuck in a flicker loop that saturates the
    -- shell. That presents as the dock/taskbar icons churning and as keyboard
    -- input "going haywire", even though the input path itself is fine. There
    -- are many issues reported related to this:
    --
    --   https://github.com/neovim/neovim/issues/12622
    --   https://github.com/neovim/neovim/issues/23650
    --   https://github.com/neovim/neovim/issues/9806
    --   https://gitlab.gnome.org/GNOME/gnome-shell/-/work_items/4938
    --   https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1035736&pow_referer=https%3A%2F%2Fgithub.com%2Fneovim%2Fneovim%2Fissues%2F23650
    --
    -- xclip goes through XWayland, where owning a selection does not require
    -- focus, and mutter mirrors the X11 selection onto the Wayland clipboard.
    -- This is a deliberate downgrade on Wayland: an X11 selection only lives as
    -- long as the process that owns it, and the XWayland bridge can lag behind
    -- native copies. It is the right trade until a compositor grows a clipboard
    -- protocol that needs no focus, so revisit this when giving Wayland another
    -- try.
    if Util.env_is_set("WAYLAND_DISPLAY")
        and Util.env_is_set("DISPLAY")
        and vim.fn.executable("xclip") == 1 then
        return "xclip"
    end

    -- Disabled on Wayland for the reason above, and kept so the native path is
    -- easy to restore. Both halves of wl-clipboard are needed: Neovim registers
    -- a copy and a paste command together, matching its own auto-detection.
    -- if Util.env_is_set("WAYLAND_DISPLAY")
    --     and vim.fn.executable("wl-copy") == 1
    --     and vim.fn.executable("wl-paste") == 1 then
    --     return "wl-copy"
    -- end

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
