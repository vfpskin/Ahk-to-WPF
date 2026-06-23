#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk
#SingleInstance Force

global ui := new XAMLGUI(A_ScriptDir "\NewDemoAlert.xaml")

InitThemeManager(ui, ["Dark", "Light", "Blue", "Green", "Purple", "Red", "Orange", "Teal"])
ApplyTheme("Dark")
ui.SetWindowProp("Background", "Transparent")

InitTitleBar(ui, {title: "MsgBox Showcase", showTheme: true, showMin: false, showMax: false})

ui.OnEvent("BtnTheme", "Click", "AlertsCycleTheme")
ui.OnEvent("BtnClose", "Click", "OnBtnClose")

ui.OnEvent("BtnAlertSuccess", "Click", "OnAlert")
ui.OnEvent("BtnAlertError",   "Click", "OnAlert")
ui.OnEvent("BtnAlertWarning", "Click", "OnAlert")
ui.OnEvent("BtnAlertInfo",    "Click", "OnAlert")
ui.OnEvent("BtnAlertQuestion","Click", "OnAlert")
ui.OnEvent("BtnInputBox",     "Click", "OnAlert")
ui.OnEvent("BtnAlert3Btns",   "Click", "OnAlert")
ui.OnEvent("BtnAlert4Btns",   "Click", "OnAlert")

ui.Show()
return

AlertsCycleTheme(state, ctrl, event)
{
    CycleTheme(state, ctrl, event)
    global ui
    ui.SetWindowProp("Background", "Transparent")
}

OnAlert(state, ctrl, event)
{
    global ui
    if (ctrl = "BtnAlertSuccess")
    {
        r := ui.Msgbox("Great job!", "The operation was completed successfully without any problems.", "success")
        ui.Update("LblResult", "Text", "Result: " r " (OK)")
    }
    else if (ctrl = "BtnAlertError")
    {
        r := ui.Msgbox("Oops...", "Something went wrong. Please try again later.", "error")
        ui.Update("LblResult", "Text", "Result: " r " (OK)")
    }
    else if (ctrl = "BtnAlertWarning")
    {
        r := ui.Msgbox("Caution!", "You are about to delete an important file. Make sure you know what you are doing.", "warning")
        ui.Update("LblResult", "Text", "Result: " r " (OK)")
    }
    else if (ctrl = "BtnAlertInfo")
    {
        r := ui.Msgbox("Notification", "You have 3 new messages in your inbox.", "info")
        ui.Update("LblResult", "Text", "Result: " r " (OK)")
    }
    else if (ctrl = "BtnAlertQuestion")
    {
        r := ui.Msgbox("Confirm", "Do you want to save the changes?", "question")
        if (r = 1)
            ui.Update("LblResult", "Text", "Result: " r " (Yes)")
        else
            ui.Update("LblResult", "Text", "Result: " r " (No)")
    }
    else if (ctrl = "BtnInputBox")
    {
        text := ui.InputBox("Write your name.", "Please enter your name to continue:")
        if (text != "")
            ui.Update("LblResult", "Text", "Input: """ text """")
        else
            ui.Update("LblResult", "Text", "Input: cancelled")
    }
    else if (ctrl = "BtnAlert3Btns")
    {
        r := ui.Msgbox("Save Changes?", "You have unsaved changes. What do you want to do?", "warning", "Save|Don't Save|Cancel")
        if (r = 1)
            ui.Update("LblResult", "Text", "Result: " r " (Save)")
        else if (r = 2)
            ui.Update("LblResult", "Text", "Result: " r " (Don't Save)")
        else
            ui.Update("LblResult", "Text", "Result: " r " (Cancel)")
    }
    else if (ctrl = "BtnAlert4Btns")
    {
        r := ui.Msgbox("Help Needed", "Select an option to continue:", "question", "Save|Discard|Cancel|Help")        
        ui.Update("LblResult", "Text", "Result: " r " (button " r ")")
    }
}

OnBtnClose(state, ctrl, event)
{
    global ui
    ui.Close()
    ExitApp
}
