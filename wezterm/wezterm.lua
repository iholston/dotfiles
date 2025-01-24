local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- wezterm.on("gui-startup", function(cmd)
--     local tab, pane, window = mux.spawn_window(cmd or {})
--     window:gui_window():maximize()
-- end)

-- Settings
config.color_scheme = "Dracula (base16)"
config.font = wezterm.font("JetBrains Mono")
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.99
config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 3000
config.default_workspace = "home"
config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe" }

-- Keys
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {

    -- Send C-a when pressed 2x
    { key = "a",          mods = "LEADER|CTRL", action = act.SendKey { key = "a", mods = "CTRL" } },

    -- Copy Mode
    { key = "c",          mods = "LEADER",      action = act.ActivateCopyMode },

    -- Resize Pane Mode
    { key = "r",          mods = "LEADER",      action = act.ActivateKeyTable { name = "resize_pane", one_shot = false } },

    -- Move Tab Mode
    { key = "m",          mods = "LEADER",      action = act.ActivateKeyTable { name = "move_tab", one_shot = false } },

    -- Pane 
    { key = "s",          mods = "LEADER",      action = act.SplitVertical { domain = "CurrentPaneDomain" } },
    { key = "v",          mods = "LEADER",      action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "q",          mods = "LEADER",      action = act.CloseCurrentPane { confirm = true } },
    { key = "z",          mods = "LEADER",      action = act.TogglePaneZoomState },
    { key = "h",          mods = "LEADER",      action = act.ActivatePaneDirection("Left") },
    { key = "j",          mods = "LEADER",      action = act.ActivatePaneDirection("Down") },
    { key = "k",          mods = "LEADER",      action = act.ActivatePaneDirection("Up") },
    { key = "l",          mods = "LEADER",      action = act.ActivatePaneDirection("Right") },

    -- Workspaces
    { key = "w",          mods = "LEADER",      action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
    { key = "D",          mods = "LEADER",      action = act.SwitchToWorkspace {
            name = "Dotfiles",
            spawn = { cwd = wezterm.home_dir .. "/GitHub/dotfiles" },
        },
    },
    { key = "L",          mods = "LEADER",      action = act.SwitchToWorkspace {
            name = 'LoL Bot',
            spawn = { cwd = wezterm.home_dir .. "/GitHub/lol-bot" },
        },
    },
    { key = "A",          mods = "LEADER",      action = act.SwitchToWorkspace {
            name = 'LoL Accept',
            spawn = { cwd = wezterm.home_dir .. "/GitHub/lol-accept" },
        },
    },

    -- Tab
    { key = "t",          mods = "LEADER",      action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n",          mods = "LEADER",      action = act.ShowTabNavigator },

    -- Move through scrollback with JK
    { key = "k",          mods = "CTRL|SHIFT",  action = act.ScrollByPage(-0.2) },
    { key = "j",          mods = "CTRL|SHIFT",  action = act.ScrollByPage(0.2) },

    -- Rename Tab
    {
        key = "e",
        mods = "LEADER",
        action = act.PromptInputLine {
            description = wezterm.format {
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { AnsiColor = "Fuchsia" } },
                { Text = "Renaming Tab Title...:" },
            },
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:active_tab():set_title(line)
                end
            end)
        }
    },
}

-- Override copy mode keys https://wezfurlong.org/wezterm/config/lua/wezterm.gui/default_key_tables.html
local copy_mode = nil
if wezterm.gui then
    copy_mode = wezterm.gui.default_key_tables().copy_mode
    table.insert(
    copy_mode,
    { key = "_", mods = "SHIFT", action = act.CopyMode "MoveToStartOfLineContent" }
    )
    table.insert(
    copy_mode,
    { key="y",   mods="NONE",    action=wezterm.action{ Multiple = {
        wezterm.action { CopyTo="ClipboardAndPrimarySelection" },
        wezterm.action { CopyMode="Close" }
    }}}
    )
end

-- Resize panes/move tabs with hjkl
config.key_tables = {
    -- Leader-r
    resize_pane = {
        { key = "h",      action = act.AdjustPaneSize { "Left", 1 } },
        { key = "j",      action = act.AdjustPaneSize { "Down", 1 } },
        { key = "k",      action = act.AdjustPaneSize { "Up", 1 } },
        { key = "l",      action = act.AdjustPaneSize { "Right", 1 } },
        { key = "Escape", action = "PopKeyTable" },
        { key = "Enter",  action = "PopKeyTable" },
    },
    -- Leader-m
    move_tab = {
        { key = "h",      action = act.MoveTabRelative(-1) },
        { key = "j",      action = act.MoveTabRelative(-1) },
        { key = "k",      action = act.MoveTabRelative(1) },
        { key = "l",      action = act.MoveTabRelative(1) },
        { key = "Escape", action = "PopKeyTable" },
        { key = "Enter",  action = "PopKeyTable" },
    },
    copy_mode = copy_mode,
}

-- Leader number to jump to tab
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.ActivateTab(i - 1)
  })
end

return config
