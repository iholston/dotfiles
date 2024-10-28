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

# Install Apps
$apps = @(
    # Terminal
    "wez.wezterm" 

    # Shell 
    "Microsoft.Powershell"
    "JanDeDobbeleer.OhMyPosh"
    "DEVCOM.JetBrainsMonoNerdFont"

    # Text/Code Editor
    "Neovim.Neovim"
    "BurntSushi.ripgrep.MSVC"
    "zig.zig" 

    # Other
    "Git.Git"
    "fzf"
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
New-Item -Path "$HOME\.config" -ItemType Directory
New-Item -Path "$HOME\.config\wezterm" -ItemType Directory
New-Item -Path "$HOME\.config\pwsh" -ItemType Directory

# Create symlinks
New-Item -Path "$HOME\.config\wezterm\wezterm.lua" -ItemType SymbolicLink -Value "$(Get-Location)\wezterm\wezterm.lua"
New-Item -Path "$HOME\.config\pwsh\user_profile.ps1" -ItemType SymbolicLink -Value "$(Get-Location)\pwsh\user_profile.ps1"
New-Item -Path "$env:LOCALAPPDATA\nvim" -ItemType SymbolicLink -Value "$(Get-Location)\nvim"


# Set user_profile for pwsh
$pattern = '. $env:USERPROFILE\.config\pwsh\user_profile.ps1'
if ($null -eq (Select-String -Path "$PROFILE" -Pattern $([regex]::escape($pattern)))) {
    Add-Content -Path "$PROFILE" -Value $pattern
}
