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
        ui.Update("OverlayTitle", "Text", "Welcome")
        ui.Update("OverlayHint", "Visibility", "Collapsed")
        ui.Update("WelcomeOverlay", "Visibility", "Visible")
        SetTimer, CerrarBienvenida, -1300
    }
    else
    {
        ui.Update("TxtStatus", "Text", "")
        ui.Update("OverlayTitle", "Text", "Login Failed")
        ui.Update("OverlayHint", "Text", "Hint: admin / 1234")
        ui.Update("OverlayHint", "Visibility", "Visible")
        ui.Update("WelcomeOverlay", "Visibility", "Visible")
        SetTimer, CerrarFail, -3500
    }
}

CerrarBienvenida:
    global ui
    ui.Close()
    ExitApp

CerrarFail:
    global ui
    ui.Update("WelcomeOverlay", "Visibility", "Collapsed")
    ui.Update("OverlayHint", "Visibility", "Collapsed")
    ui.Update("TxtStatus", "Text", "Invalid credentials. Hint: admin / 1234")
    ui.Update("TxtStatus", "Foreground", "#FF6B6B")
    return
