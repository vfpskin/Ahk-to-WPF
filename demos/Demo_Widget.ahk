#NoEnv
SetBatchLines, -1
#SingleInstance Force
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk

; --- DEMO 2: Floating System Widget ---
; Demonstrates creating a borderless floating widget that can be
; dragged (thanks to x:Name="TitleBar" in XAML) and how to
; update progress bars in real-time from AHK.

global ui := new XAMLGUI("Demo_Widget.xaml")

; Initialize title bar (no min/max buttons for widget)
InitTitleBar(ui, {title: "SYSTEM MONITOR", showMin: false, showMax: false, onClose: "Widget_OnClose"})

ui.Show()

; Iniciamos un temporizador para simular lectura de recursos
SetTimer, UpdateStats, 1000

return

UpdateStats:
    ; Simular valores de 0 a 100
    Random, cpuVal, 10, 95
    Random, ramVal, 40, 85
    
    ; Update ProgressBars (Value)
    ui.Update("ProgCPU", "Value", cpuVal)
    ui.Update("ProgRAM", "Value", ramVal)
    
    ; Update Texts
    ui.Update("TxtCPU", "Text", cpuVal "%")
    ui.Update("TxtRAM", "Text", ramVal "%")
    
    ; Change CPU color if too high (simulating thermal alert)
    if (cpuVal > 80)
    {
        ui.Update("ProgCPU", "Foreground", "#FF4D4D") ; Rojo
        ui.Update("TxtCPU", "Foreground", "#FF4D4D")
    }
    else
    {
        ui.Update("ProgCPU", "Foreground", "#00E676") ; Verde
        ui.Update("TxtCPU", "Foreground", "#00E676")
    }
return

; Custom close handler: stop timer before closing
Widget_OnClose(state, ctrl, event) {
    SetTimer, UpdateStats, Off
    global ui
    ui.Close()
    ExitApp
}
