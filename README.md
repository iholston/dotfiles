# iholston's dotfiles
Dotfiles for Windows and Neovim

## Terminal Emulator
### Wezterm

> Over-engineered terminal emulator/multiplexer, great fundamental features, cross-platform, and is entirely configured in Lua

KeyMaps:
  - `LDR` = `C-a`
  - `LDR c`: Copy mode
  - `LDR s/v`: Create a split pane
  - `LDR hjkl`: Navigate pane
  - `LDR q`: Close pane
  - `LDR z`: Zoom pane
  - `LDR r`: `resize_pane` mode. Use `hjkl` to resize pane and `ESC` or `Enter` to confirm
  - `LDR t`: New tab
  - `LDR 1-9`: Navigate tab by index
  - `LDR n`: Launch tab navigator
  - `LDR e`: Rename tab title
  - `LDR m`: `move_tab` mode. Use `hj`/`kl` to move tabs and `ESC` or `Enter` to confirm
  - `LDR w`: Workspace launcher
  - `$ wezterm show-keys --lua` to get the Lua table of all keybindings available

## Shell
### pwsh

> Powershell Core not Windows Powershell v5.1

Config:
- I followed [@kiranraaj19](https://github.com/kiranraaj19)'s helpful guide [here](https://github.com/kiranraaj19/pwsh)
- [Oh-my-posh](https://ohmyposh.dev/)
- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons)
- [PSFzf](https://github.com/kelleyma49/PSFzf)
- [LazyGit](https://github.com/jesseduffield/lazygit)
- OneHalfDark Theme
- Misc utility funcs

## Text Editors
### Neovim

> theprimeagean converted me

Config/Keys:
- I mostly followed [@cpow](https://github.com/cpow)'s series [here](https://www.youtube.com/playlist?list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn)
- `LDR` = `Space`

## Scripts
### AutoHotKey

> perfect for Windows hotkeys

HotKeys:
- `` C-` ``: Save replay (AMD ReLive)
- `C-1`: Open/focus/minimize firefox
  - `C-j/k`: Send up/down in firefox
- `C-2`: Open/focus/minimize wezterm
- `C-3`: Open/focus/minimize discord
- `C-8`: Send single down click
- `C-9`: Autoclicker
- `C-0`: Close anything related to Riot Games


