;                      _______________________________________________
;                    _-'    .-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.  --- `-_
;                 _-'.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.--.  .-.-.`-_
;              _-'.-.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-`__`. .-.-.-.`-_
;           _-'.-.-.-.-. .-----.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-----. .-.-.-.-.`-_
;        _-'.-.-.-.-.-. .---.-. .-----------------------------. .-.---. .---.-.-.-.`-_
;       :-----------------------------------------------------------------------------:
;       `---._.-----------------------------------------------------------------._.---'
;       AutoHotKey script that enables some simple Windows hotkeys

; Firefox 
#IfWinNotExist ahk_class MozillaWindowClass
^1::
    Run, firefox.exe
    WinWait, ahk_class MozillaWindowClass,, 5
    IfWinNotActive, ahk_class MozillaWindowClass 
    {
        WinActivate, ahk_class MozillaWindowClass
    }
Return

#IfWinExist ahk_class MozillaWindowClass
^1::
    WinGet, winState, MinMax, ahk_class MozillaWindowClass
    if WinActive("ahk_class MozillaWindowClass")
    {
        WinMinimize, ahk_class MozillaWindowClass
    }
    else if (winState = -1) ; -1 Min, 1 Maxed
    {
        WinRestore, ahk_class MozillaWindowClass
        WinMaximize, ahk_class MozillaWindowClass    
    }
    else 
    {
        WinActivate, ahk_class MozillaWindowClass
    }
Return

#IfWinActive ahk_class MozillaWindowClass
^j::
    Send {Down}
Return

^k::
    Send {Up}
Return

; Wezterm
#IfWinNotExist ahk_class org.wezfurlong.wezterm
^2::
    Run, "C:\Program Files\WezTerm\wezterm-gui.exe"
    WinWait, ahk_class org.wezfurlong.wezterm,, 5
    If WinNotActive, ahk_class org.wezfurlong.wezterm
    {
        WinActivate, ahk_class org.wezfurlong.wezterm
    }
Return

#IfWinExist ahk_class org.wezfurlong.wezterm
^2::
    WinGet, winState, MinMax, ahk_class org.wezfurlong.wezterm
    if WinActive("ahk_class org.wezfurlong.wezterm")
    {
        WinMinimize, ahk_class org.wezfurlong.wezterm
    }
    else if (winState = -1) 
    {
        WinRestore, ahk_class org.wezfurlong.wezterm
        WinMaximize, ahk_class org.wezfurlong.wezterm
    }
    else 
    {
        WinActivate, ahk_class org.wezfurlong.wezterm
    }
Return

; Discord
#If !WinExist("ahk_exe Discord.exe")
^3::
    Run, "C:\Users\Jarvis\AppData\Local\Discord\Update.exe" --processStart Discord.exe
    WinWait, ahk_class Discord.exe,, 5
    If WinNotActive, ahk_class Discord.exe
    {
        WinActivate, ahk_class Discord.exe
    }
Return

#If WinExist("ahk_exe Discord.exe")
^3::
    WinGet, activeID, ID, A
    WinGet, processName, ProcessName, ahk_id %activeID%
    if (processName == "Discord.exe")
    {
        WinMinimize, ahk_exe Discord.exe
    }
    else 
    {
        WinActivate, ahk_exe Discord.exe
    }
Return

; Obsidian
#If !WinExist("ahk_exe Obsidian.exe")
^4::
    Run, "C:\Users\Jarvis\AppData\Local\Obsidian\Obsidian.exe"
    WinWait, ahk_class Obsidian.exe,, 5
    If WinNotActive, ahk_class Obsidian.exe
    {
        WinActivate, ahk_class Obsidian.exe
    }
Return

#If WinExist("ahk_exe Obsidian.exe")
^4::
    WinGet, activeID, ID, A
    WinGet, processName, ProcessName, ahk_id %activeID%
    if (processName == "Obsidian.exe")
    {
        WinMinimize, ahk_exe Obsidian.exe
    }
    else 
    {
        WinActivate, ahk_exe Obsidian.exe
    }
Return

; Hold down click
^8::
    if (getkeystate("LButton")) {
        click, up
    } else {
        click, down
    }
Return    

; Autoclicker
global ClickState := false
^9:: 
    if (ClickState) 
    {
        SetTimer, SendClick, off
        ClickState := false
        MsgBox, AutoClicker Off
        Return
    }

    InputBox, millis, AutoClicker, Enter time in milliseconds:,, 200, 100
    if (ErrorLevel || millis + 0 != millis)
    {
        MsgBox, No interval set. Exiting
        Return
    }

    ClickState := true
    SetTimer, SendClick, %millis%

    SendClick:
        Click
        Return
Return

; Close all Riot Games
^0::
    processList := ["RiotClientCrashHandler.exe", "RiotClientUx.exe", "RiotClientServices.exe", "VALORANT.exe", "VALORANT-Win64-Shipping.exe", "LeagueClient.exe", "League of Legends.exe" ] 
    for index, processName in processList
    {
        Process, Close, %processName%
    }
Return
