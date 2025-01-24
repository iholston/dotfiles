local wezterm   = require("wezterm")
local act       = wezterm.action
local mux       = wezterm.mux
local config    = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Basic Settings
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrains Mono")
config.window_decorations = "RESIZE"
config.window_background_opacity = 1
config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 3000
config.default_workspace = "home"
config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe" }

-- KeyBinds
config.leader = { key = "w", mods = "ALT", timeout_milliseconds = 1000 }
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
    { key = "q",          mods = "LEADER",      action = act.CloseCurrentPane { confirm = false } },
    { key = "z",          mods = "LEADER",      action = act.TogglePaneZoomState },
    { key = "h",          mods = "LEADER",      action = act.ActivatePaneDirection("Left") },
    { key = "j",          mods = "LEADER",      action = act.ActivatePaneDirection("Down") },
    { key = "k",          mods = "LEADER",      action = act.ActivatePaneDirection("Up") },
    { key = "l",          mods = "LEADER",      action = act.ActivatePaneDirection("Right") },

    -- Move through scrollback with JK
    { key = "k",          mods = "CTRL|SHIFT",  action = act.ScrollByPage(-0.2) },
    { key = "j",          mods = "CTRL|SHIFT",  action = act.ScrollByPage(0.2) },

    -- Tab
    { key = "t",          mods = "LEADER",      action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n",          mods = "LEADER",      action = act.ShowTabNavigator },

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

return config
