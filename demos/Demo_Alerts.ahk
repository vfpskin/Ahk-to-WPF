#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk
#SINGLEINSTANCE FORCE

; --- DEMO: SweetAlert Showcase ---
global ui := new XAMLGUI("Demo_Alerts.xaml")

; Initialize theme system
InitThemeManager(ui, ["Dark", "Light", "Blue", "Green", "Purple", "Red", "Orange", "Teal"])
ApplyTheme("Dark")
ui.SetWindowProp("Background", "Transparent")

; Initialize title bar (card-style, no min/max buttons)
InitTitleBar(ui, {title: "Alert Showcase", showTheme: true, showMin: false, showMax: false})

; Register events
ui.OnEvent("BtnTheme", "Click", "AlertsCycleTheme")

ui.OnEvent("BtnAlertSuccess", "Click", "Alert_Events")
ui.OnEvent("BtnAlertError", "Click", "Alert_Events")
ui.OnEvent("BtnAlertWarning", "Click", "Alert_Events")
ui.OnEvent("BtnAlertInfo", "Click", "Alert_Events")
ui.OnEvent("BtnInputBox", "Click", "Alert_Events")
ui.OnEvent("SI_InputText", "Enter", "EnterSI_InputText")

; SweetAlert overlay events
ui.OnEvent("BtnSA_OK", "Click", "SA_OnClick")

; InputBox overlay events
ui.OnEvent("BtnSI_OK", "Click", "SI_OnClick")
ui.OnEvent("BtnSI_Cancel", "Click", "SI_OnClick")


ui.Show()
return


EnterSI_InputText(state, ctrl, event){
    global ui, SI_Callback, SI_PendingText
    SI_PendingText := state["SI_InputText"]
    ui.Update("SweetInputOverlay", "Visibility", "Collapsed")
    SetTimer, _DoSICallback, -50
}

_DoSICallback:
    global SI_Callback, SI_PendingText
    if (SI_Callback != "" && IsFunc(SI_Callback))
    {
        fn := Func(SI_Callback)
        fn.Call(SI_PendingText)
    }
return

; Theme cycle wrapper: applies theme then restores transparency
AlertsCycleTheme(state, ctrl, event)
{
    CycleTheme(state, ctrl, event)
    global ui
    ui.SetWindowProp("Background", "Transparent")
}

Main_Events(state, ctrl, event)
{
    global ui
    if (ctrl = "BtnClose")
    {
        ui.Close()
        ExitApp
    }
}

Alert_Events(state, ctrl, event)
{
    if (ctrl = "BtnAlertSuccess")
    {
        ShowOverlayAlert("Great job!","The operation was completed successfully without any problems.", "success")
    }
    else if (ctrl = "BtnAlertError")
    {
        ShowOverlayAlert("Oops...", "Something went wrong. Please try again later.", "error")
    }
    else if (ctrl = "BtnAlertWarning")
    {
        ShowOverlayAlert("Caution!", "You are about to delete an important file. Make sure you know what you are doing.", "warning")
    }
    else if (ctrl = "BtnAlertInfo")
    {
        ShowOverlayAlert("Notification", "You have 3 new messages in your inbox.", "info")
    }
    else if (ctrl = "BtnInputBox")
    {
        ShowOverlayInput("Write your name.", "Please enter your name to continue:", "OnInputBoxResult")
    }
}

OnInputBoxResult(text)
{
 
    if (text != "")
        ShowOverlayAlert("Hello!", "Nice to meet you " . text . ".", "success")
    else
        ShowOverlayAlert("Cancelled", "You didn't enter a name.", "warning")
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
        ; Hide overlay
        ui.Update("SweetAlertOverlay", "Visibility", "Collapsed")
        
        ; Execute callback
        if (SA_Callback != "" && IsFunc(SA_Callback))
        {
            %SA_Callback%()
        }
    }
}

; ======================================================================
; SWEET INPUT OVERLAY LOGIC
; ======================================================================
global SI_Callback := ""

ShowOverlayInput(title, message, callback:="")
{
    global ui, SI_Callback
    SI_Callback := callback

    ; Update texts
    ui.Update("SI_TxtTitle", "Text", title)
    ui.Update("SI_TxtMessage", "Text", message)
    
    ; Clear TextBox
    ui.Update("SI_InputText", "Text", "")

    ; Show overlay
    ui.Update("SweetInputOverlay", "Visibility", "Visible")
    ui.Focus("SI_InputText")
}

SI_OnClick(state, ctrl, event)
{
    global ui, SI_Callback
    
    
    if (ctrl = "BtnSI_OK")
    {
        inputText := state["SI_InputText"]
        if (SI_Callback != "" && IsFunc(SI_Callback))
        {
            fn := Func(SI_Callback)
            fn.Call(inputText)
        }
    }
    else if (ctrl = "BtnSI_Cancel")
    {
        if (SI_Callback != "" && IsFunc(SI_Callback))
        {
            fn := Func(SI_Callback)
            fn.Call("")
        }
    }
   ; Ocultar overlay
    ui.Update("SweetInputOverlay", "Visibility", "Collapsed")
 
}

OnBtnClose(state, ctrl, event)
{
    global ui
    ui.Close()
    ExitApp
}

