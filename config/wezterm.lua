local wezterm = require 'wezterm'

local act = wezterm.action

local config = {}

function get_wsl_domain()
    -- This should match the entry in the list output by `wsl --list` that
    -- should be used as the default domain
    local wsl_domain_name = os.getenv("WEZTERM_WSL_DOMAIN")
    if not wsl_domain_name or wsl_domain_name == "" then
        wsl_domain_name = "WSL:Ubuntu"
    else
        wsl_domain_name = "WSL:" .. wsl_domain_name
    end
    return wsl_domain_name
end

function get_shell(tab_info)
    local shell = ''
    if tab_info.active_pane.domain_name == "local" then
        shell = '(Git Bash) '
    elseif tab_info.active_pane.domain_name == get_wsl_domain() then
        shell = '(WSL) '
    end
    return shell
end

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
    local index = ''
    if #tabs > 1 then
        index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
    end
    return index .. get_shell(tab) .. tab.active_pane.title
end)

function tab_title(tab_info)
    local title = tab_info.tab_title
    if title and #title > 0 then
        return title
    end
    return tab_info.active_pane.title
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    return get_shell(tab) .. tab_title(tab)
end)

config.default_prog = {"bash"}
config.default_domain = get_wsl_domain()

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

local switch_to_git_bash = function(window, pane)
  -- Save a reference to the current tab so we can close it after
  -- creating the new tab
  local existing_tab = window:active_tab()

  -- Launch Git Bash in a new tab
  window:perform_action(
    act.SpawnCommandInNewTab {
      args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" },
      domain = { DomainName = 'local' },
    },
    pane
  )

  -- The new tab is automatically focused, save a reference it is as well
  local new_tab = window:active_tab()

  -- Set the active tab's title to "Git Bash"
  new_tab:set_title("Git Bash")

  -- Gross but it seems like there's only an action to close the current
  -- tab and I can't find a way from lua to close a specific tab. So,
  -- activate the old tab, close it, and then re-activate the new tab
  existing_tab:activate()
  window:perform_action(
      wezterm.action.CloseCurrentTab { confirm = false },
      pane
  )
end

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

  { key = 'g', mods = 'LEADER', action = wezterm.action_callback(switch_to_git_bash), },
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

