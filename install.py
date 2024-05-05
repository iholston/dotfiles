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
import ctypes

# Check if running as admin
try:
    is_admin = os.getuid() == 0
except AttributeError:
    is_admin = ctypes.windll.shell32.IsUserAnAdmin()
if not is_admin:
    print("   Error. Program must be run as administrator.")
    exit()

# path of target symlink : location of source file in repo
tasks = {
    # pwsh
    '~/.config/pwsh': 'pwsh',

    # neovim
    '~/.config/nvim': 'nvim',
    "{}/{}".format(os.getenv('LOCALAPPDATA'), 'nvim'): 'nvim',

    # wezterm
    '~/.config/wezterm': 'wezterm',

    # dotfiles location
    '~/.config/dotfiles': '../dotfiles',
}

print("Creating symbolic links")
current_dir = os.path.abspath(os.path.dirname(__file__))
for target, source in tasks.items():
    source = os.path.join(current_dir, os.path.expanduser(source))
    target = os.path.expanduser(target)
    try:
        os.symlink(source, target)
        print("Successfully created symlink for {}".format(source))
    except FileExistsError:
        print("{} already exists".format(source))
    except Exception as e:
        print("Unknown exception: {}".format(e))
