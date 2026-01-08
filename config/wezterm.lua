local wezterm = require 'wezterm'

local act = wezterm.action

local config = {}

-- Track panes that should be closed when a new tab is spawned from the launcher
local initial_startup_pane_id = nil
local launcher_replace_pane_id = nil

function get_shell(tab_info)
    local shell = ''
    local domain_name = tab_info.active_pane.domain_name
    if domain_name == "local" then
        -- Distinguish between Git Bash, Powershell, and other local shells
        local process = tab_info.active_pane.foreground_process_name
        if process then
            if process:find("bash") then
                shell = '(Git Bash) '
            elseif process:find("powershell") or process:find("pwsh") then
                shell = '(pwsh) '
            end
        end
    elseif domain_name:sub(1, 4) == "WSL:" then
        -- Match any WSL domain (WSL:Ubuntu, WSL:Debian, etc.)
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

-- On startup, show the launch menu to let user choose which shell to run
wezterm.on('gui-startup', function(cmd)
    local mux = wezterm.mux

    -- If wezterm was started with command line args, respect them
    if cmd and cmd.args and #cmd.args > 0 then
        local tab, pane, window = mux.spawn_window(cmd)
        return
    end

    -- Otherwise, spawn default window (Powershell for fast startup)
    -- and immediately show the launcher
    local tab, pane, window = mux.spawn_window({})

    -- Save the initial pane ID so we can auto-close it if user picks something else
    initial_startup_pane_id = pane:pane_id()

    window:gui_window():perform_action(
        wezterm.action.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS' },
        pane
    )
end)

-- Auto-close a tab when user selects something from the launcher
-- Used for both startup and the "replace current tab" launcher shortcut
wezterm.on('update-status', function(window, pane)
    -- Check if we have any pane to potentially close
    local pane_id_to_close = initial_startup_pane_id or launcher_replace_pane_id
    if pane_id_to_close == nil then
        return
    end

    local mux_window = window:mux_window()
    local tabs = mux_window:tabs()

    -- Only act if there's more than one tab (user selected something from launcher)
    if #tabs <= 1 then
        return
    end

    -- Find and close the tracked tab
    for _, tab in ipairs(tabs) do
        for _, p in ipairs(tab:panes()) do
            if p:pane_id() == pane_id_to_close then
                -- Clear IDs first to prevent re-entry
                initial_startup_pane_id = nil
                launcher_replace_pane_id = nil
                -- Activate the tab to close, then close it
                tab:activate()
                window:perform_action(
                    wezterm.action.CloseCurrentTab { confirm = false },
                    p
                )
                return
            end
        end
    end
end)

-- Use Powershell as default for fast startup (launcher lets user choose)
config.default_prog = {"powershell"}
config.default_domain = "local"

-- Build launch menu dynamically to include all WSL distributions
local function build_launch_menu()
    local menu = {}

    -- Add all WSL domains dynamically
    for _, domain in ipairs(wezterm.default_wsl_domains()) do
        table.insert(menu, {
            label = domain.name,
            domain = { DomainName = domain.name },
        })
    end

    -- Add Windows shells
    table.insert(menu, {
        label = "Powershell",
        args = {"powershell"},
        domain = { DomainName = 'local' },
    })
    table.insert(menu, {
        label = "Git Bash",
        args = {"C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l"},
        domain = { DomainName = 'local' },
    })

    return menu
end

config.launch_menu = build_launch_menu()

-- Configure leader key; use the same leader as Kitty so they act similarly.
-- timeout_milliseconds defaults to 1000 and can be omitted
config.leader = { key = ' ', mods = 'CTRL' }

-- Spawn a new tab matching the current pane's shell type
local spawn_tab_like_current = function(window, pane)
    local domain_name = pane:get_domain_name()

    if domain_name == "local" then
        -- In local domain, check if current pane is running Git Bash
        local process = pane:get_foreground_process_name()
        if process and (process:find("bash") or process:find("bash.exe")) then
            -- Spawn Git Bash
            window:perform_action(
                act.SpawnCommandInNewTab {
                    args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" },
                    domain = { DomainName = 'local' },
                },
                pane
            )
            return
        end
    end

    -- For WSL domains or other local processes, use CurrentPaneDomain
    window:perform_action(act.SpawnTab 'CurrentPaneDomain', pane)
end

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
  { key = 'c', mods = 'LEADER', action = wezterm.action_callback(spawn_tab_like_current), },
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

  -- Launch menu
  { key = 'o', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS' }, },
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

