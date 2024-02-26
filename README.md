# iholston's dotfiles

## Terminal Emulator
### Wezterm

> Over-engineered terminal emulator, nailed the fundamental features, configured in Lua, and works great on Windows and MacOS

KeyMaps:
  - `LDR` = `C-a`
  - `LDR c`: Copy mode
  - `LDR s/v`: Create a split pane
  - `LDR hjkl`: Navigate pane
  - `LDR q`: Close pane
  - `LDR z`: Zoom pane
  - `LDR o`: Rotate pane
  - `LDR r`: `resize_pane` mode. Use `hjkl` to resize pane and `ESC` or `Enter` to confirm
  - `LDR t`: New tab
  - `LDR [/]` Navigate tab
  - `LDR 1-9`: Navigate tab by index
  - `LDR n`: Launch tab navigator
  - `LDR e`: Rename tab title
  - `LDR m`: `move_tab` mode. Use `hj`/`kl` to move tabs and `ESC` or `Enter` to confirm
      - `LDR {/}`: Move tab without entering the `move_tab` mode
  - `LDR w`: Workspace launcher
  - `$ wezterm show-keys --lua` to get the Lua table of all keybindings available

## Shell
### pwsh

> Powershell Core not Windows Powershell v5.1

Config:
- I followed [@kiranraaj19](https://github.com/kiranraaj19)'s helpful guide [here](https://github.com/kiranraaj19/pwsh)
- Oh-my-posh
- Terminal-Icons
- PSFzf
- OneHalfDark Theme
- Misc utility funcs

## Text Editors
### Neovim

> theprimeagean converted me

Config/Keys:
- I mostly followed [@cpow](https://github.com/cpow)'s series [here](https://www.youtube.com/playlist?list=PLsz00TDipIffreIaUNk64KxTIkQaGguqn)
- `LDR` = `Space`

