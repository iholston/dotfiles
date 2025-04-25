local wezterm   = require("wezterm")
local act       = wezterm.action
local config    = wezterm.config_builder()

-- Basic Settings
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrains Mono")
config.font_size = 14
config.window_decorations = "RESIZE" 
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe" }

-- KeyBinds
config.leader = { key = "w", mods = "ALT", timeout_milliseconds = 1000 }
config.keys   = {

    -- Copy Mode
    { key = "c",          mods = "LEADER",      action = act.ActivateCopyMode },

    -- Move through scrollback with JK
    { key = "k",          mods = "CTRL|SHIFT",  action = act.ScrollByPage(-0.2) },
    { key = "j",          mods = "CTRL|SHIFT",  action = act.ScrollByPage(0.2) },

    -- Pane 
    { key = "s",          mods = "LEADER",      action = act.SplitVertical { domain = "CurrentPaneDomain" } },
    { key = "v",          mods = "LEADER",      action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "h",          mods = "LEADER",      action = act.ActivatePaneDirection("Left") },
    { key = "j",          mods = "LEADER",      action = act.ActivatePaneDirection("Down") },
    { key = "k",          mods = "LEADER",      action = act.ActivatePaneDirection("Up") },
    { key = "l",          mods = "LEADER",      action = act.ActivatePaneDirection("Right") },

    -- Tab
    { key = "t",          mods = "LEADER",      action = act.SpawnTab("CurrentPaneDomain") },
    { key = "w",          mods = "LEADER",      action = act.CloseCurrentPane { confirm = false } },
    { key = "n",          mods = "LEADER",      action = act.ShowTabNavigator },
}

return config
