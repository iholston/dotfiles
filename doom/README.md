# Doom Emacs configuration

This directory is the public, portable core of the Doom Emacs configuration.
It contains no internal packages, hosts, URLs, usernames, or work paths.

## Files

- `init.el` — enabled Doom modules.
- `packages.el` — public package declarations plus the optional work-package loader.
- `config.el` — ordered public module loads plus the optional work-config loader.
- `lisp/ui.el` — theme, fonts, modeline, and Which-Key provenance.
- `lisp/platform.el` — executable paths and graphical/TTY platform behavior.
- `lisp/tabs.el` — workspace-aware Centaur Tabs behavior and bindings.
- `lisp/navigation.el` — line movement, wrapping, Evil motions, and scrolling.
- `lisp/org.el` — notes, agenda, Org behavior, presentation, and helpers.
- `lisp/terminal.el` — Ghostel, Yazi, Treemacs, and project opening.
- `lisp/windows.el` — dividers, splits, horizontal panning, and zoom.
- `lisp/workspaces.el` — workspace selection, ordering, and navigation.
- `lisp/editing.el` — buffers, Markdown, clipboard, Docker helpers, and context menus.

## Keybinding provenance

Which-Key makes binding ownership explicit:

- Unmarked descriptions are standard Doom/Emacs/package bindings.
- Cyan `[P]` descriptions are public custom bindings from this directory.
- Magenta `[W]` descriptions are private bindings supplied by the optional work overlay.

The text badges remain readable in monochrome terminals.

## Notes directory

The default notes directory is:

```text
~/Documents/Obsidian Vault/
```

Override it before launching Emacs:

```sh
export DOOM_NOTES_DIR="$HOME/Documents/Notes"
```

If the directory does not exist, Doom starts normally with an empty Org
agenda. The configuration does not create the directory automatically. Once
the directory appears, the next agenda or todo-list invocation discovers its
Org files without requiring an Emacs restart.

## Optional work overlay

By default, the public config looks for two optional private entry points:

```text
~/.config/doom-work/
├── config.el      # runtime configuration
└── packages.el    # package declarations
```

Either file may be absent. The private overlay can keep supporting modules,
scripts, or tests in any layout and load them from its own `config.el`; the
public configuration does not depend on that internal structure.

If that directory is absent, the public configuration loads normally without
work functionality.

Environment controls:

```sh
DOOM_WORK_CONFIG=0                 # force public-only mode
DOOM_WORK_CONFIG=1                 # permit work overlay loading
DOOM_WORK_CONFIG_DIR=/other/path   # use another private overlay path
```

Unset `DOOM_WORK_CONFIG` means automatic mode: load the overlay only when its
files exist.

Run `doom sync` after changing either public or work `packages.el`. Restart
Emacs after package changes; ordinary config changes can use Doom reload.

## Installation

This directory is a Doom user configuration, not a standalone Emacs
configuration. Install Doom itself at `~/.emacs.d`, then link this directory as
`~/.doom.d`:

```sh
ln -s "$HOME/dotfiles/doom" "$HOME/.doom.d"
"$HOME/.emacs.d/bin/doom" sync
```

If `~/.doom.d` already exists, preserve or remove it before creating the link.
Restart Emacs after the initial sync. The private work overlay is optional and
is discovered automatically when present.
