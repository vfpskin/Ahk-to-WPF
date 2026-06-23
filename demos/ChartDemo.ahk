#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\ChartDemo.xaml")

ui.OnEvent("BtnLoad",  "Click", "OnLoad")
ui.OnEvent("BtnColumn", "Click", "OnColumn")
ui.OnEvent("BtnLine",   "Click", "OnLine")
ui.OnEvent("BtnPie",    "Click", "OnPie")
ui.OnEvent("BtnBar",    "Click", "OnBar")
ui.OnEvent("BtnArea",   "Click", "OnArea")
ui.OnEvent("BtnClose",  "Click", "OnClose")

; Cargar datos por defecto
OnLoad("", "", "")

ui.Show()
return

OnLoad(state, ctrl, event)
{
    global ui
    ui.Update("Chart1", "Title", "Ventas 2024")
    ui.Update("Chart1", "ChartType", "Column")
    ui.Update("Chart1", "Data", "Serie1|Ene|120|Feb|200|Mar|150|Abr|80|May|250|Jun|180")
    ui.Update("Chart1", "AddSeries", "Serie2|Ene|90|Feb|180|Mar|130|Abr|110|May|200|Jun|160")
    ui.Update("LblStatus", "Text", "Column chart - 2 series loaded")
}

OnColumn(state, ctrl, event)
{
    global ui
    ui.Update("Chart1", "ChartType", "Column")
    ui.Update("LblStatus", "Text", "Chart type: Column")
}

OnLine(state, ctrl, event)
{
    global ui
    ui.Update("Chart1", "ChartType", "Line")
    ui.Update("LblStatus", "Text", "Chart type: Line")
}

OnPie(state, ctrl, event)
{
    global ui
    ui.Update("Chart1", "ChartType", "Pie")
    ui.Update("LblStatus", "Text", "Chart type: Pie")
}

OnBar(state, ctrl, event)
{
    global ui
    ui.Update("Chart1", "ChartType", "Bar")
    ui.Update("LblStatus", "Text", "Chart type: Bar")
}

OnArea(state, ctrl, event)
{
    global ui
    ui.Update("Chart1", "ChartType", "Area")
    ui.Update("LblStatus", "Text", "Chart type: Area")
}

OnClose(state, ctrl, event)
{
    ui.Close()
    ExitApp
}
