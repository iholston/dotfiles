Write-Host @"

   @iholston's              ███████╗██╗██╗     ███████╗███████╗
   ██████╗  █████╗ ████████╗██╔════╝██║██║     ██╔════╝██╔════╝
   ██╔══██╗██╔══██╗╚══██╔══╝█████╗  ██║██║     █████╗  ███████╗
   ██║  ██║██║  ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
   ██████╔╝╚█████╔╝   ██║   ██║     ██║███████╗███████╗███████║
   ╚═════╝  ╚════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

   https://github.com/iholston/dotfiles

"@

# Check if running as Admin
if (!([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "   Error. Program must be run as administrator."
    Read-Host -Prompt "   Press Enter to exit"
    Exit
} 

$ErrorActionPreference = 'Continue'

# Install Apps
$apps = @(
    # Terminal 
    "wez.wezterm" 
    "sxyazi.yazi"
    "Git.Git"
    "7zip.7zip"
    "jqlang.jq"
    "sharkdp.fd"
    "BurntSushi.ripgrep.MSVC"
    "junegunn.fzf"
    "ajeetdsouza.zoxide"
    "ImageMagick.ImageMagick"
    

    # Shell 
    "Microsoft.Powershell"
    "JanDeDobbeleer.OhMyPosh"
    "DEVCOM.JetBrainsMonoNerdFont"

    # Text/Code Editor
    "Neovim.Neovim"
    "zig.zig" # required for neovim packages

    # Other
    "AutoHotkey.AutoHotkey"
    "Clement.bottom"
)

foreach ($app in $apps) {
    Write-Output "Installing $app"
    winget install --accept-package-agreements --accept-source-agreements $app -s winget
    Write-Host ""
    Write-Host ""
}

Install-Module -Name Terminal-Icons -Repository PSGallery

# Create config folders
New-Item -Path "$HOME\.config\wezterm" -ItemType Directory -Force
New-Item -Path "$HOME\.config\pwsh" -ItemType Directory -Force

# Create symlinks
New-Item -Path "$HOME\.config\wezterm\wezterm.lua" -ItemType SymbolicLink -Value "$(Get-Location)\wezterm\wezterm.lua"
New-Item -Path "$HOME\.config\pwsh\profile.ps1" -ItemType SymbolicLink -Value "$(Get-Location)\pwsh\profile.ps1"
New-Item -Path "$env:LOCALAPPDATA\nvim" -ItemType SymbolicLink -Value "$(Get-Location)\nvim"

# Set user_profile for pwsh
$pattern = '. $env:USERPROFILE\.config\pwsh\profile.ps1'
if ($null -eq (Select-String -Path "$PROFILE" -Pattern $([regex]::escape($pattern)))) {
    Add-Content -Path "$PROFILE" -Value $pattern
}
