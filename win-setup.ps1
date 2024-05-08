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
    "Microsoft.Powershell"
    "Neovim.Neovim"
    "wez.wezterm"
    "python3"
    "Git.Git"
    "JanDeDobbeleer.OhMyPosh"
    "BurntSushi.ripgrep.MSVC"
    "fzf"
    "AutoHotkey.AutoHotkey"
    "Clement.bottom"
    "chocolatey.chocolatey" 
)

foreach ($app in $apps) {
    Write-Output "Installing $app"
    winget install --accept-package-agreements --accept-source-agreements $app -s winget
    Write-Host ""
}

# NFs can't be installed w/winget atm
choco install nerd-fonts-jetbrainsmono -y

Install-Module -Name Terminal-Icons -Repository PSGallery

# Set user_profile for pwsh
$pattern = '. $env:USERPROFILE\.config\pwsh\user_profile.ps1'
if ((Select-String -Path "$PROFILE" -Pattern $([regex]::escape($pattern))) -eq $null) {
    Add-Content -Path "$PROFILE" -Value $pattern
}
