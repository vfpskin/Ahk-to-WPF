#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk
#SINGLEINSTANCE FORCE

; --- DEMO 1: Modern Login Screen ---
global ui := new XAMLGUI(A_ScriptDir "\Demo_Login.xaml")

; Initialize theme system (transparency overlay for card-based layout)
InitThemeManager(ui, ["Dark", "Light", "Blue", "Green", "Purple", "Red", "Orange", "Teal"])
ApplyTheme("Dark")
ui.SetWindowProp("Background", "Transparent")

; Initialize title bar (card-style, no min/max buttons)
InitTitleBar(ui, {title: "Welcome Back", showTheme: true, showMin: false, showMax: false})

; Register events
ui.OnEvent("BtnTheme", "Click", "LoginCycleTheme")
ui.OnEvent("BtnLogin", "Click", "Login_Event")
ui.OnEvent("BtnLogin", "Enter", "Login_Event")
ui.OnEvent("TxtUser", "Enter", "TxtUserEnter")
ui.OnEvent("TxtPass", "Enter", "TxtPassEnter")

; SweetAlert overlay events
ui.OnEvent("BtnSA_OK", "Click", "SA_OnClick")

ui.Show()


sleep, 100
ui.Focus("TxtUser")
return

; Theme cycle wrapper: applies theme then restores transparency
LoginCycleTheme(state, ctrl, event)
{
    CycleTheme(state, ctrl, event)
    global ui
    ui.SetWindowProp("Background", "Transparent")
}

TxtUserEnter(state, ctrl, event)
{
    global ui
    ui.Focus("TxtPass")
}
TxtPassEnter(state, ctrl, event)
{
    global ui
    ui.Focus("BtnLogin")
}

Login_Event(state, ctrl, event)
{
    global ui
    
    if (ctrl = "BtnClose")
    {
        ui.Close()
        ExitApp
    }
    else if (ctrl = "BtnLogin")
    {
        user := state["TxtUser"]
        pass := state["TxtPass"]
        
        if (user = "admin" && pass = "1234")
        {
            ui.Update("TxtStatus", "Foreground", "#00FF00")
            ui.Update("TxtStatus", "Text", "Login successful! Welcome.")
            ShowOverlayAlert("Login successful", "Access was authorized successfully.", "success", "OnLoginSuccess")
        }
        else if (user = "" || pass = "")
        {
            ui.Update("TxtStatus", "Foreground", "#FF4D4D")
            ui.Update("TxtStatus", "Text", "Please enter username and password.")
            ShowOverlayAlert("Login error", "You must enter username and password.", "warning")
        }
        else
        {
            ui.Update("TxtStatus", "Foreground", "#FF4D4D")
            ui.Update("TxtStatus", "Text", "Invalid credentials (Use admin / 1234).")
            ShowOverlayAlert("Login error", "Invalid username or password.", "error")
        }
    }
}

OnLoginSuccess()
{
    global ui
    Sleep, 500
    ui.Close()
    ExitApp
}

; ======================================================================
; SWEET ALERT OVERLAY LOGIC
; ======================================================================
global SA_Callback := ""

ShowOverlayAlert(title, message, iconType:="info", callback:="")
{
    global ui, SA_Callback
    SA_Callback := callback

    ; Update texts
    ui.Update("SA_TxtTitle", "Text", title)
    ui.Update("SA_TxtMessage", "Text", message)

    ; Hide all icons
    ui.Update("SA_IcoInfo", "Visibility", "Collapsed")
    ui.Update("SA_IcoSuccess", "Visibility", "Collapsed")
    ui.Update("SA_IcoError", "Visibility", "Collapsed")
    ui.Update("SA_IcoWarning", "Visibility", "Collapsed")

    ; Show requested icon
    if (iconType = "info")
        ui.Update("SA_IcoInfo", "Visibility", "Visible")
    else if (iconType = "success")
        ui.Update("SA_IcoSuccess", "Visibility", "Visible")
    else if (iconType = "error")
        ui.Update("SA_IcoError", "Visibility", "Visible")
    else if (iconType = "warning")
        ui.Update("SA_IcoWarning", "Visibility", "Visible")

    ; Show OK button
    ui.Update("BtnSA_OK", "Visibility", "Visible")

    ; Show overlay
    ui.Update("SweetAlertOverlay", "Visibility", "Visible")
    ui.Focus("BtnSA_OK")
}

SA_OnClick(state, ctrl, event)
{
    global ui, SA_Callback
    if (ctrl = "BtnSA_OK")
    {
        ; Hide overlay immediately
        ui.Update("SweetAlertOverlay", "Visibility", "Collapsed")
        
        ; Execute callback if exists
        if (SA_Callback != "" && IsFunc(SA_Callback))
        {
            %SA_Callback%()
        }
    }
}
