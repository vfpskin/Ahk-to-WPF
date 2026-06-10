#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk

#SINGLEINSTANCE FORCE
; --- DEMO 1: Modern Login Screen ---
; Demonstrates PasswordBox, rounded styles, shadows,
; and user validation by reading the "state" returned by WPF.

global ui := new XAMLGUI("Demo_Login_Gradient.xaml")

; Initialize title bar (card-style, no min/max buttons)
InitTitleBar(ui, {title: "Welcome Back", showMin: false, showMax: false})

; Register events
ui.OnEvent("BtnLogin", "Click", "Login_Event")
ui.OnEvent("BtnLogin", "Enter", "Login_Event")
ui.OnEvent("TxtUser", "Enter", "TxtUserEnter")
ui.OnEvent("TxtPass", "Enter", "TxtPassEnter")

ui.Show()
sleep, 100
ui.Focus("TxtUser")
return


TxtUserEnter(state, ctrl, event)
{
    global ui
    ui.Focus("TxtPass")
    ;MsgBox, Control: %ctrl% | Evento: %event%
}
TxtPassEnter(state, ctrl, event)
{
    global ui
    ui.Focus("BtnLogin")
    ;MsgBox, Control: %ctrl% | Evento: %event%
}
; --- Event reception from XAML ---
Login_Enter(state, ctrl, event)
{
    global ui

    if (ctrl = "TxtUser")
    {
        ui.Focus("TxtPass")
    }
    else if (ctrl = "TxtPass")
    {
        ui.Focus("BtnLogin")
    }
}

Login_Event(state, ctrl, event)
{
    if (ctrl = "BtnClose")
    {
        ui.Close()
        ExitApp
    }
    else if (ctrl = "BtnLogin")
    {
        ; state is an associative array with the state of ALL controls
        user := state["TxtUser"]
        pass := state["TxtPass"]
        
        ; Validate credentials (static example)
        if (user = "admin" && pass = "1234")
        {
            ui.Update("TxtStatus", "Foreground", "#00FF00")
            ui.Update("TxtStatus", "Text", "Login successful! Welcome.")
            MsgBox, 64, Login successful, Access was authorized successfully.
            
            Sleep, 1500
            ui.Close()
            ExitApp
        }
        else if (user = "" || pass = "")
        {
            ui.Update("TxtStatus", "Foreground", "#FF4D4D")
            ui.Update("TxtStatus", "Text", "Please enter username and password.")
            MsgBox, 48, Login error, You must enter username and password.
        }
        else
        {
            ui.Update("TxtStatus", "Foreground", "#FF4D4D")
            ui.Update("TxtStatus", "Text", "Invalid credentials (Use admin / 1234).")
            MsgBox, 16, Login error, Invalid username or password.
        }
    }
}
