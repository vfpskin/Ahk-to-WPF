#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\Demo_Animation_Login.xaml")

InitTitleBar(ui, {title: "Animation Login", showTheme: false, showMin: false, showMax: false})

ui.OnEvent("BtnLogin", "Click", "Login_Event")

ui.Show()
return

Login_Event(state, ctrl, event)
{
    global ui
    user := state["TxtUser"]
    pass := state["TxtPass"]

    if (user = "admin" && pass = "1234")
    {
        ui.Update("TxtStatus", "Text", "Welcome!")
        ui.Update("TxtStatus", "Foreground", "#6BCB77")
        Sleep, 800
        ui.Close()
        ExitApp
    }
    else
    {
        ui.Update("TxtStatus", "Text", "Invalid credentials")
        ui.Update("TxtStatus", "Foreground", "#FF6B6B")
    }
}
