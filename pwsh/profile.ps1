# Oh-my-posh 
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_lean.omp.json" | Invoke-Expression

# Terminal Icons
Import-Module -Name Terminal-Icons

# Which 
function which ($command) {
	Get-Command -Name $command -ErrorAction SilentlyContinue |
	  Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Zoxide
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

# Upgraded yazi, changes directory to yazi location
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath $cwd
    }
    Remove-Item -Path $tmp
}

# Configured fzf to show previews and cd to directory of found file
# nvim (ff) => nvim a specific file and be in file dir
function ff {
    $file = Get-ChildItem -File -Recurse | Select-Object -ExpandProperty FullName | fzf --preview 'type {} | more' --bind 'ctrl-p:toggle-preview'
    if ($file) {
        Set-Location (Split-Path -Path $file -Parent)
        return (Split-Path -Path $file -Leaf)
    }
}

# Configured fzf to show only directories and cd to selected directory
# nvim (fd) => open nvim on selected directory
function fd {
   $dir = (Get-ChildItem -Directory -Recurse | Select-Object -ExpandProperty FullName | fzf)
   if ($dir) { 
       Set-Location $dir
       return $dir
    }
}

