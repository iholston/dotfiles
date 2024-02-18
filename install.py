'''
   @iholston's              ███████╗██╗██╗     ███████╗███████╗
   ██████╗  █████╗ ████████╗██╔════╝██║██║     ██╔════╝██╔════╝
   ██╔══██╗██╔══██╗╚══██╔══╝█████╗  ██║██║     █████╗  ███████╗
   ██║  ██║██║  ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
   ██████╔╝╚█████╔╝   ██║   ██║     ██║███████╗███████╗███████║
   ╚═════╝  ╚════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

   https://github.com/iholston/dotfiles
'''
print(__doc__)

import os

# path of target symlink : location of source file in repo
tasks = {
    # pwsh
    '~/.config/pwsh': 'pwsh',

    # neovim
    '~/.config/nvim': 'nvim',

    # git
    '~/.gitignore': 'git/gitignore',

    # wezterm
    '~/.config/wezterm': 'wezterm',

    # misc
    '~/.ideavimrc': 'misc/ideavimrc'
}

print("Creating symbolic links")
current_dir = os.path.abspath(os.path.dirname(__file__))
for target, source in tasks.items():
    source = os.path.join(current_dir, os.path.expanduser(source))
    target = os.path.expanduser(target)
    try:
        os.symlink(source, target)
        print("Successfully created simlink for {}".format(source))
    except FileExistsError:
        print("File already exists")
    except Exception as e:
        print("Unknown exception: {}".format(e))
