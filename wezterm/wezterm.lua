local wezterm   = require("wezterm")
local act       = wezterm.action
local config    = wezterm.config_builder()

-- 🎨 Theme switcher function
local function theme_switcher(window, pane)
  local schemes = wezterm.get_builtin_color_schemes()
  local choices = {}

  -- Collect all scheme names
  for name, _ in pairs(schemes) do
    table.insert(choices, { label = name, id = name })
  end

  -- Sort alphabetically
  table.sort(choices, function(a, b)
    return a.label < b.label
  end)

  window:perform_action(
    act.InputSelector({
      title = "🎨 Pick a Theme!",
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if not id and not label then
          return
        end
        inner_window:set_config_overrides({
          color_scheme = id or label,
        })
      end),
    }),
    pane
  )
end

-- Basic Settings
config.color_scheme = "Ivory Light (terminal.sexy)"
-- config.font = wezterm.font("JetBrains Mono")
config.font = wezterm.font("SF Mono", {weight = "Medium"})
config.font_size = 16
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"

if wezterm.target_triple:find("windows") then
  config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe" }
end

-- KeyBinds
config.leader = { key = "w", mods = "ALT", timeout_milliseconds = 1000 }
config.keys   = {

  -- Copy Mode
  { key = "c", mods = "LEADER",     action = act.ActivateCopyMode },

  -- Move through scrollback with JK
  { key = "k", mods = "CTRL|SHIFT", action = act.ScrollByPage(-0.2) },
  { key = "j", mods = "CTRL|SHIFT", action = act.ScrollByPage(0.2) },

  -- Pane
  { key = "s", mods = "LEADER",     action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "v", mods = "LEADER",     action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "h", mods = "LEADER",     action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER",     action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER",     action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER",     action = act.ActivatePaneDirection("Right") },

  -- Tab
  { key = "t", mods = "LEADER",     action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "LEADER",     action = act.CloseCurrentPane { confirm = false } },
  { key = "n", mods = "LEADER",     action = act.ShowTabNavigator },

  -- 🎨 Theme picker: Ctrl+Shift+T
  {
    key = "T",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(theme_switcher),
  },

  -- Toggle pane zoom
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

  -- Enter resize mode
  { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}

config.key_tables = {
  resize_pane = {
    { key = "LeftArrow",  action = act.AdjustPaneSize { "Left", 1 } },
    { key = "RightArrow", action = act.AdjustPaneSize { "Right", 1 } },
    { key = "UpArrow",    action = act.AdjustPaneSize { "Up", 1 } },
    { key = "DownArrow",  action = act.AdjustPaneSize { "Down", 1 } },
    { key = "Escape",     action = "PopKeyTable" },
    { key = "Enter",      action = "PopKeyTable" },
  }
}

config.window_padding = {
  bottom = 0,
}

return config
