# Terminal Theme 
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_lean.omp.json" | Invoke-Expression
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/robbyrussell.omp.json" | Invoke-Expression

# Terminal Icons
Import-Module -Name Terminal-Icons

# Zoxide - replace cd with zioxide
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

# PSFzf 
Import-Module PSFzf 
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -EnableAliasFuzzyKillProcess

# Which 
function which ($command) {
	Get-Command -Name $command -ErrorAction SilentlyContinue |
	  Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Clears shada files for neovim
function clear_shada {
    Remove-Item -Path "$env:USERPROFILE\AppData\Local\nvim-data\shada" -Recurse -Force
}

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

# https://dev.to/kevinnitro/fzf-advanced-integration-in-powershell-53p0#command
# better fzf for finding files/directories
function _fzf_open_path
{
  param (
    [Parameter(Mandatory=$true)]
    [string]$input_path
  )
  if ($input_path -match "^.*:\d+:.*$")
  {
    $input_path = ($input_path -split ":")[0]
  }
  if (-not (Test-Path $input_path))
  {
    return
  }
  $cmds = @{
    'bat' = { bat $input_path }
    'cat' = { Get-Content $input_path }
    'cd' = {
      if (Test-Path $input_path -PathType Leaf)
      {
        $input_path = Split-Path $input_path -Parent
      }
      Set-Location $input_path
    }
    'nvim' = { nvim $input_path }
    'remove' = { Remove-Item -Recurse -Force $input_path }
    'echo' = { Write-Output $input_path }
  }
  $cmd = $cmds.Keys | fzf --prompt 'Select command> '
  & $cmds[$cmd]
}

function _fzf_get_path_using_fd
{
  $input_path = fd --type file --follow --hidden --exclude .git |
    fzf --prompt 'Files> ' `
      --header-first `
      --header 'CTRL-S: Switch between Files/Directories' `
      --bind 'ctrl-s:transform:if not "%FZF_PROMPT%"=="Files> " (echo ^change-prompt^(Files^> ^)^+^reload^(fd --type file^)) else (echo ^change-prompt^(Directory^> ^)^+^reload^(fd --type directory^))' `
      --preview 'if "%FZF_PROMPT%"=="Files> " (bat --color=always {} --style=plain) else (eza -T --colour=always --icons=always {})'
  return $input_path
}

function _fzf_get_path_using_rg
{
  $INITIAL_QUERY = "${*:-}"
  $RG_PREFIX = "rg --column --line-number --no-heading --color=always --smart-case"
  $input_path = "" |
    fzf --ansi --disabled --query "$INITIAL_QUERY" `
      --bind "start:reload:$RG_PREFIX {q}" `
      --bind "change:reload:sleep 0.1 & $RG_PREFIX {q} || rem" `
      --bind 'ctrl-s:transform:if not "%FZF_PROMPT%" == "1. ripgrep> " (echo ^rebind^(change^)^+^change-prompt^(1. ripgrep^> ^)^+^disable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-f ^& type %TEMP%\rg-fzf-r) else (echo ^unbind^(change^)^+^change-prompt^(2. fzf^> ^)^+^enable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-r ^& type %TEMP%\rg-fzf-f)' `
      --color 'hl:-1:underline,hl+:-1:underline:reverse' `
      --delimiter ':' `
      --prompt '1. ripgrep> ' `
      --preview-label 'Preview' `
      --header 'CTRL-S: Switch between ripgrep/fzf' `
      --header-first `
      --preview 'bat --color=always {1} --highlight-line {2} --style=plain' `
      --preview-window 'up,60%,border-bottom,+{2}+3/3'
  return $input_path
}

function fdg
{
  _fzf_open_path $(_fzf_get_path_using_fd)
}

function rgg
{
  _fzf_open_path $(_fzf_get_path_using_rg)
}


# SET KEYBOARD SHORTCUTS TO CALL FUNCTION

Set-PSReadLineKeyHandler -Key "Ctrl+f" -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("fdg")
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key "Ctrl+g" -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("rgg")
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

