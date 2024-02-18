;                      _______________________________________________
;                    _-'    .-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.  --- `-_
;                 _-'.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.--.  .-.-.`-_
;              _-'.-.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-`__`. .-.-.-.`-_
;           _-'.-.-.-.-. .-----.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-----. .-.-.-.-.`-_
;        _-'.-.-.-.-.-. .---.-. .-----------------------------. .-.---. .---.-.-.-.`-_
;       :-----------------------------------------------------------------------------:
;       `---._.-----------------------------------------------------------------._.---'

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
    else if (winState = -1) ; -1 Min, 1 Maxed
    {
        WinRestore, ahk_class org.wezfurlong.wezterm
        WinMaximize, ahk_class org.wezfurlong.wezterm
    }
    else 
    {
	WinActivate, ahk_class org.wezfurlong.wezterm
    }
Return

; Autoclicker(s)
^8::
    if (getkeystate("LButton")) {
        click, up
    } else {
        click, down
    }
Return    

^9::
Return
