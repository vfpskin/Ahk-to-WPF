#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\Demo_Animation_Login.xaml")

InitThemeManager(ui, ["Dark", "Light", "Blue", "Green", "Purple", "Red", "Orange", "Teal"])
ApplyTheme("Dark")
ui.SetWindowProp("Background", "Transparent")

InitTitleBar(ui, {title: "Animation Login", showTheme: false, showMin: false, showMax: false})

ui.OnEvent("BtnLogin", "Click", "Login_Event")
ui.OnEvent("BtnTheme", "Click", "AlertsCycleTheme")

ui.Show()
return

AlertsCycleTheme(state, ctrl, event)
{
    CycleTheme(state, ctrl, event)
    global ui
    ui.SetWindowProp("Background", "Transparent")
}

Login_Event(state, ctrl, event)
{
    global ui
    user := state["TxtUser"]
    pass := state["TxtPass"]

    if (user = "admin" && pass = "1234")
    {
        ui.Update("TxtStatus", "Text", "Login successful!")
        ui.Update("TxtStatus", "Foreground", "#6BCB77")
    }
    else
    {
        ui.Update("TxtStatus", "Text", "Invalid credentials")
        ui.Update("TxtStatus", "Foreground", "#FF6B6B")
    }
}
