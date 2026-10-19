# Doom Emacs configuration

This directory is the public, portable core of the Doom Emacs configuration.
It contains no internal packages, hosts, URLs, usernames, or work paths.

## Files

- `init.el` — enabled Doom modules.
- `packages.el` — public declarations plus optional overlay package loaders.
- `config.el` — ordered public module loads plus optional overlay loaders.
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
- Magenta `[W]` descriptions are private bindings supplied by the work overlay.
- Green `[C]` descriptions are machine-local bindings supplied by the Canvas overlay.

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

## Optional overlays

The public core supports independent work and Canvas overlays:

```text
~/.config/doom-work/
├── config.el
└── packages.el

~/.config/doom-canvas/
├── config.el
└── packages.el
```

The work overlay defaults to automatic discovery. Either work file may be
absent; supporting modules, scripts, and tests can remain within that private
directory.

```sh
DOOM_WORK_CONFIG=0                 # force public-only mode
DOOM_WORK_CONFIG=1                 # permit work overlay loading
DOOM_WORK_CONFIG_DIR=/other/path   # use another work overlay path
```

The Canvas overlay is explicitly opt-in so merely having local files does not
change ordinary installations:

```sh
DOOM_CANVAS_CONFIG=1
DOOM_CANVAS_CONFIG_DIR="$HOME/.config/doom-canvas"
```

Run `doom sync` after changing any `packages.el`. Restart Emacs after package
changes; ordinary config changes can use Doom reload.

## Installation

This directory is a Doom user configuration, not a standalone Emacs
configuration. Install Doom itself, then link or set `DOOMDIR` to this
directory and run `doom sync`.

The primary installation uses the Emacs 32 Canvas app with an isolated Doom
runtime under `~/.emacs32-canvas`; its environment sets:

```sh
DOOMDIR="$HOME/Code/dotfiles/doom"
DOOM_CANVAS_CONFIG=1
DOOM_CANVAS_CONFIG_DIR="$HOME/.config/doom-canvas"
```

This keeps the public directory as the single core source of truth while work
and machine-local Canvas behavior remain outside Git.
