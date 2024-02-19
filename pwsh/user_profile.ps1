# Prompt 
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_lean.omp.json" | Invoke-Expression

# Terminal Icons
Import-Module -Name Terminal-Icons

# PSFzf 
import-Module PSFzf
Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'

# PSReadline
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# Set-PSReadLineKeyHandler -Key Tab -Function AcceptSuggestion

# Alias
Set-Alias grep findstr

# Utils
function which ($command) {
	Get-Command -Name $command -ErrorAction SilentlyContinue |
	  Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
function weather() {
    Invoke-RestMethod wttr.in/Colorado-Springs?0 
}
function dotc {
    nvim $env:USERPROFILE\OneDrive\Programming\github\dotfiles
}
function toggle_ahk { # Some steam games don't run if ahk is running
    $ahk = Get-Process AutoHotkeyU64 -ErrorAction SilentlyContinue
    if ($ahk) {
        $ahk | Stop-Process -Force
        Write-Output "ahk terminated"
    } else {
        & "$env:USERPROFILE\OneDrive\Programming\github\dotfiles\scripts\win-keys.ahk"
        Write-Output "ahk started"
    }
}
