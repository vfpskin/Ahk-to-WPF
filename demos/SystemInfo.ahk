; Script AHK 1.1 - SystemInfo con Progress y GUI
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

tempFile := A_Temp "\sysinfo.txt"

; Delete previous file if exist
FileDelete, %tempFile%

; Run systeminfo and save in a TXT
Run, %ComSpec% /c systeminfo > "%tempFile%",, Hide

; Show progress bar
Gui, Add, Text,, Loading system info...
Gui, Add, Progress, w300 h20 vBar, 0
Gui, Show,, SystemInfo - AHK

progress := 0
Loop {    
    progress += 5
    if (progress > 100)
        progress := 100
    GuiControl,, Bar, %progress%

    ; If file exist and is not empty
    if FileExist(tempFile) {
        FileGetSize, size, %tempFile%
        if (size > 0) {
            break
        }
    }
    Sleep, 1000
}

; Read TXT content
FileRead, output, %tempFile%

; Close Progress GUI
Gui, Destroy

; Show final Informatin GUI
Gui, Add, Text, w400 h20, Información del sistema (Windows 7)
Gui, Add, Edit, w600 h400 vSysInfo ReadOnly, %output%
Gui, Add, Button, gSalir, Cerrar
Gui, Show,, SystemInfo - AHK
return

Salir:
GuiClose:
ExitApp

