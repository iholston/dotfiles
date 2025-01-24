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

$ErrorActionPreference = "Continue"

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
    "zig.zig" 

    # Other
    "GlazeWM"
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

# Create .config folder symlink to dotfiles repo
New-Item -Path "$HOME\.config" -ItemType SymbolicLink -Value "$(Get-Location)" 

# Add app specific environment variables
[Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", "C:\Program Files\Git\usr\bin\file.exe", [System.EnvironmentVariableTarget]::User) # # https://yazi-rs.github.io/docs/installation#windows 
[Environment]::SetEnvironmentVariable("YAZI_CONFIG_HOME", "$HOME\.config\yazi", [System.EnvironmentVariableTarget]::User) # https://yazi-rs.github.io/docs/configuration/overview/
[Environment]::SetEnvironmentVariable("GLAZEWM_CONFIG_PATH", "$HOME\.config\glaze\config.yaml", [System.EnvironmentVariableTarget]::User) # https://github.com/glzr-io/glazewm?tab=readme-ov-file#config-documentation
[Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", "$HOME\.config", [System.EnvironmentVariableTarget]::User) 

# Set user_profile for pwsh
$pattern = '. $env:USERPROFILE\.config\pwsh\profile.ps1'
if ($null -eq (Select-String -Path "$PROFILE" -Pattern $([regex]::escape($pattern)))) {
    Add-Content -Path "$PROFILE" -Value $pattern
}

