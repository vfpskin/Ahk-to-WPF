#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

; --- DEMO: SweetAlert Showcase ---
global ui := new XAMLGUI(A_ScriptDir "\Circular ProgressBar_UC.xaml")


; Register events
ui.OnEvent("CloseBtn", "Click", "OnBtnClose")
ui.OnEvent("Start_Btn", "Checked", "OnPlayChecked")
ui.OnEvent("Start_Btn", "Unchecked", "OnPlayUnchecked")
ui.OnEvent("SetBtn", "Click", "OnSetClick")
ui.OnEvent("CreditLink", "Click", "OnCreditClick")

global g_progress := 0
global g_pi := 4 * ATan(1)

ui.Show()
return

OnBtnClose(state, ctrl, event)
{
    global ui
    ui.Close()
    ExitApp
}

OnPlayChecked(state, ctrl, event)
{
    global ui, g_progress
    g_progress := 0
    SetTimer, UpdateProgress, 50
}

OnPlayUnchecked(state, ctrl, event)
{
    global g_progress
    SetTimer, UpdateProgress, Off
    g_progress := 0
    UpdateProgressRing(0)
}

UpdateProgress:
    global ui, g_progress
    g_progress += 1
    if (g_progress > 100)
    {
        SetTimer, UpdateProgress, Off
        ui.Update("Start_Btn", "IsChecked", "0")
        return
    }
    UpdateProgressRing(g_progress)
return

OnCreditClick(state, ctrl, event)
{
    Run, https://github.com/CSharpDesignPro/WPF---Circular-Radial-Progress-Bar-UserControl
}

OnSetClick(state, ctrl, event)
{
    global ui, g_progress
    val := state["SetValueBox"]
    if val is not number
        return
    val := val + 0
    if (val < 0 or val > 100)
        return
    SetTimer, UpdateProgress, Off
    g_progress := val
    UpdateProgressRing(val)
}

; Call from any AHK script: CircularPB("55") or CircularPB(55)
CircularPB(percent)
{
    global ui
    if !ui
        return
    UpdateProgressRing(percent + 0)
}

UpdateProgressRing(progress)
{
    global ui, g_pi
    
    if (progress = 0)
    {
        ui.Update("ProgRing", "Data", "M 0,0")
        ui.Update("TimerLabel", "Text", "0")
        return
    }
    
    if (progress = 100)
    {
        pathData := "F1 M 210,105 A 105,105 0 1 1 0,105 A 105,105 0 1 1 210,105"
        pathData .= " M 200,105 A 95,95 0 1 0 10,105 A 95,95 0 1 0 200,105 Z"
        ui.Update("ProgRing", "Data", pathData)
        ui.Update("TimerLabel", "Text", "100")
        return
    }
    
    startAngle := -g_pi / 2
    endAngle := startAngle + progress * 2 * g_pi / 100
    
    outerR := 105
    innerR := 95
    cx := 105
    cy := 105
    
    outerSX := cx + outerR * Cos(startAngle)
    outerSY := cy + outerR * Sin(startAngle)
    outerEX := cx + outerR * Cos(endAngle)
    outerEY := cy + outerR * Sin(endAngle)
    
    innerEX := cx + innerR * Cos(endAngle)
    innerEY := cy + innerR * Sin(endAngle)
    innerSX := cx + innerR * Cos(startAngle)
    innerSY := cy + innerR * Sin(startAngle)
    
    isLargeArc := (progress > 50) ? 1 : 0
    
    pathData := "M " . Round(outerSX, 3) . "," . Round(outerSY, 3)
    pathData .= " A " . outerR . "," . outerR . " 0 " . isLargeArc . " 1 " . Round(outerEX, 3) . "," . Round(outerEY, 3)
    pathData .= " L " . Round(innerEX, 3) . "," . Round(innerEY, 3)
    pathData .= " A " . innerR . "," . innerR . " 0 " . isLargeArc . " 0 " . Round(innerSX, 3) . "," . Round(innerSY, 3)
    pathData .= " Z"
    
    ui.Update("ProgRing", "Data", pathData)
    ui.Update("TimerLabel", "Text", progress)
}


