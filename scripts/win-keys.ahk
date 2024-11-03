;                      _______________________________________________
;                    _-'    .-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.  --- `-_
;                 _-'.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.--.  .-.-.`-_
;              _-'.-.-.-. .---.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-`__`. .-.-.-.`-_
;           _-'.-.-.-.-. .-----.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-----. .-.-.-.-.`-_
;        _-'.-.-.-.-.-. .---.-. .-----------------------------. .-.---. .---.-.-.-.`-_
;       :-----------------------------------------------------------------------------:
;       `---._.-----------------------------------------------------------------._.---'
;       AutoHotKey script that handles Windows hotkeys

#Requires AutoHotkey v2.0.2
#SingleInstance Force

Komorebic(cmd) {
    RunWait(format("komorebic.exe {}", cmd), , "Hide")
}

; Open Apps
!f:: {
    if !WinExist("ahk_exe firefox.exe") {
        Run("firefox.exe")
    }
}

!w:: {
    if !WinExist("ahk_exe wezterm-gui.exe") {
        Run("C:\Program Files\WezTerm\wezterm-gui.exe")
    }
}

!d:: {
    if !WinExist("ahk_exe Discord.exe") {
        Run("C:\Users\Jarvis\AppData\Local\Discord\Update.exe --processStart Discord.exe")
    }
}
    
; Komorebi
!q::Komorebic("close")
!m::Komorebic("minimize")

; Focus windows
!h::Komorebic("focus left")
!j::Komorebic("focus down")
!k::Komorebic("focus up")
!l::Komorebic("focus right")

!+[::Komorebic("cycle-focus previous")
!+]::Komorebic("cycle-focus next")

; Move windows
!+h::Komorebic("move left")
!+j::Komorebic("move down")
!+k::Komorebic("move up")
!+l::Komorebic("move right")

; Stack windows
!Left::Komorebic("stack left")
!Down::Komorebic("stack down")
!Up::Komorebic("stack up")
!Right::Komorebic("stack right")
!;::Komorebic("unstack")
![::Komorebic("cycle-stack previous")
!]::Komorebic("cycle-stack next")

; Resize
!=::Komorebic("resize-axis horizontal increase")
!-::Komorebic("resize-axis horizontal decrease")
!+=::Komorebic("resize-axis vertical increase")
!+_::Komorebic("resize-axis vertical decrease")

; Manipulate windows
!t::Komorebic("toggle-float")
!n::Komorebic("toggle-monocle")

; Window manager options
!+r::Komorebic("retile")
!p::Komorebic("toggle-pause")

; Layouts
!x::Komorebic("flip-layout horizontal")
!y::Komorebic("flip-layout vertical")

; Workspaces
!1::Komorebic("focus-workspace 0")
!2::Komorebic("focus-workspace 1")
!3::Komorebic("focus-workspace 2")
!4::Komorebic("focus-workspace 3")
!5::Komorebic("focus-workspace 4")
!6::Komorebic("focus-workspace 5")
!7::Komorebic("focus-workspace 6")
!8::Komorebic("focus-workspace 7")

; Move windows across workspaces
!+1::Komorebic("move-to-workspace 0")
!+2::Komorebic("move-to-workspace 1")
!+3::Komorebic("move-to-workspace 2")
!+4::Komorebic("move-to-workspace 3")
!+5::Komorebic("move-to-workspace 4")
!+6::Komorebic("move-to-workspace 5")
!+7::Komorebic("move-to-workspace 6")
!+8::Komorebic("move-to-workspace 7")

F1::Komorebic("focus-monitor 1")
F2::Komorebic("focus-monitor 0")


#HotIf WinActive("ahk_class MozillaWindowClass")
^j:: {
    Send("{Down}")
}

^k:: {
    Send("{Up}")
}
#HotIf

; Hold down click
^8:: {
    if (GetKeyState("LButton")) {
        Click("up")
    } else {
        Click("down")
    }
}    

; Autoclicker
global ClickState := false
^9:: {
    if (ClickState) 
    {
        SetTimer(SendClick, "off")
        ClickState := false
        MsgBox("AutoClicker Off")
        Return
    }

    InputBox(&millis, "AutoClicker", "Enter time in milliseconds:", "w200 h100")
    if (millis + 0 != millis)
    {
        MsgBox("No interval set. Exiting")
        Return
    }

    ClickState := true
    SetTimer(SendClick, millis)

    SendClick() {
        Click()
    }
}

; Close all Riot Games
^0:: {
    processList := ["RiotClientCrashHandler.exe", "RiotClientUx.exe", "RiotClientServices.exe", "VALORANT.exe", "VALORANT-Win64-Shipping.exe", "LeagueClient.exe", "League of Legends.exe" ] 
    for processName in processList {
        ProcessClose(processName)
    }
}
