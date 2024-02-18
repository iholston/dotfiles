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
    WinGet, MinMax, MinMax, ahk_class MozillaWindowClass
    if (MinMax = -1)
    {
        WinRestore, ahk_class MozillaWindowClass
        WinMaximize, ahk_class MozillaWindowClass
    }
    else if WinActive("ahk_class MozillaWindowClass")
    {
        WinMinimize, ahk_class MozillaWindowClass
    }
    else
    {
        WinActivate, ahk_class MozillWindowClass
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
    WinGet, MinMax, MinMax, ahk_class org.wezfurlong.wezterm
    if (MinMax = -1)
    {
        WinRestore, ahk_class org.wezfurlong.wezterm
        WinMaximize, ahk_class org.wezfurlong.wezterm
    }
    else 
    {
        IfWinActive, ahk_class org.wezfurlong.wezterm
        {
            WinMinimize, ahk_class org.wezfurlong.wezterm
        }
        else
        {
            WinActivate, ahk_class org.wezfulong.wezterm
        }
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
