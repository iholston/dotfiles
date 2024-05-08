#Requires -RunAsAdministrator

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
    Write-Output "Installing $app..."
    winget install --accept-package-agreements --accept-source-agreements $app -s winget
}

# NFs can't be installed w/winget atm
choco install nerd-fonts-jetbrainsmono -y

Install-Module -Name Terminal-Icons -Repository PSGallery

# Set user_profile for pwsh
$pattern = '. $env:USERPROFILE\.config\pwsh\user_profile.ps1'
if ((Select-String -Path "$PROFILE" -Pattern $([regex]::escape($pattern))) -eq $null) {
    Add-Content -Path "$PROFILE" -Value $pattern
}
