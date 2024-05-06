local wezterm = require 'wezterm'

local act = wezterm.action

local config = {}

config.default_prog = {"bash"}
config.default_domain = 'WSL:Ubuntu'

config.launch_menu = {
    {
        label = "WSL",
        args = {"bash"},
        domain = 'DefaultDomain',
    },
    {
        label = "Powershell",
        args = {"powershell"},
        domain = { DomainName = 'local' },
    },
    {
        label = "Git Bash",
        args = {"C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l"},
        domain = { DomainName = 'local' },
    },
}

-- Configure leader key; use the same leader as Kitty so they act similarly.
-- timeout_milliseconds defaults to 1000 and can be omitted
config.leader = { key = ' ', mods = 'CTRL' }

-- Key bindings
config.keys = {
  { key = '\\', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  { key = '-',  mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' }, },

  -- Tab management and navigation
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain', },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0), },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1), },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2), },
  { key = '4', mods = 'LEADER', action = act.ActivateTab(3), },
  { key = '5', mods = 'LEADER', action = act.ActivateTab(4), },
  { key = '6', mods = 'LEADER', action = act.ActivateTab(5), },
  { key = '7', mods = 'LEADER', action = act.ActivateTab(6), },
  { key = '8', mods = 'LEADER', action = act.ActivateTab(7), },
  { key = '9', mods = 'LEADER', action = act.ActivateTab(8), },
  { key = '0', mods = 'LEADER', action = act.ActivateTab(9), },
  { key = 't', mods = 'LEADER', action = act.ShowTabNavigator },
  { key = 'LeftArrow',  mods = 'LEADER', action = act.ActivatePaneDirection 'Left', },
  { key = 'h',          mods = 'LEADER', action = act.ActivatePaneDirection 'Left', },
  { key = 'RightArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Right', },
  { key = 'l',          mods = 'LEADER', action = act.ActivatePaneDirection 'Right', },
  { key = 'UpArrow',    mods = 'LEADER', action = act.ActivatePaneDirection 'Up', },
  { key = 'k',          mods = 'LEADER', action = act.ActivatePaneDirection 'Up', },
  { key = 'DownArrow',  mods = 'LEADER', action = act.ActivatePaneDirection 'Down', },
  { key = 'j',          mods = 'LEADER', action = act.ActivatePaneDirection 'Down', },
}

-- This is super annoying to me so disable it
config.hide_mouse_cursor_when_typing = false

-- Start flavours - wezterm

-- Base16 Outrun Dark

config.colors = {
    background = '#00002a',
    foreground = '#d0d0fa',
    cursor_fg = '#00002a',
    cursor_bg = '#d0d0fa',
    ansi = {
        '#00002a',
        '#ff4242',
        '#59f176',
        '#f3e877',
        '#66b0ff',
        '#f10596',
        '#0ef0f0',
        '#d0d0fa',
    },
    brights = {
        '#50507a',
        '#ff4242',
        '#59f176',
        '#f3e877',
        '#66b0ff',
        '#f10596',
        '#0ef0f0',
        '#f5f5ff',
    },
}
-- End flavours - wezterm

return config

