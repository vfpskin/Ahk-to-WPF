; ======================================================================
; TitleBar.ahk -- Centralized Title Bar Management
;
; Provides a reusable title bar with Minimize, Maximize/Restore, and
; Close buttons, plus optional Theme button support. All demos use the
; same event handlers via x:Name convention on TitleBar elements.
;
; Usage:
;   #Include %A_ScriptDir%\..\TitleBar.ahk
;   ui := new XAMLGUI("Demo.xaml")
;   InitTitleBar(ui, {title: "My App"})
;
; Configuration:
;   title       - Window title text
;   showTheme   - Show theme toggle button (default: false)
;   showMin     - Show minimize button (default: true)
;   showMax     - Show maximize/restore button (default: true)
;   onClose     - Custom close function name
;                 (default: TitleBar_OnClose -- closes window + ExitApp)
;
; XAML requirements (standardized names):
;   x:Name="TitleBar"    on the title bar Border (enables C# drag-to-move)
;   x:Name="LblTitle"    TextBlock for window title
;   x:Name="BtnTheme"    Theme toggle button (Visibility controlled by AHK)
;   x:Name="BtnMinimize" Minimize button (Visibility controlled by AHK)
;   x:Name="BtnMaximize" Maximize/Restore button (Visibility controlled by AHK)
;   x:Name="BtnClose"    Close button
; ======================================================================

InitTitleBar(ui, config := "") {
    if !IsObject(config)
        config := {}

    ; Set window title text
    if config.HasKey("title")
        ui.Update("LblTitle", "Text", config.title)

    ; Show/hide optional buttons
    showTheme := config.HasKey("showTheme") ? config.showTheme : false
    showMin   := config.HasKey("showMin")   ? config.showMin   : true
    showMax   := config.HasKey("showMax")   ? config.showMax   : true

    if showTheme
        ui.Update("BtnTheme", "Visibility", "Visible")
    if showMin
        ui.Update("BtnMinimize", "Visibility", "Visible")
    if showMax
        ui.Update("BtnMaximize", "Visibility", "Visible")

    ; Register standard event handlers
    fnClose := config.HasKey("onClose") ? config.onClose : "TitleBar_OnClose"
    ui.OnEvent("BtnClose",    "Click", fnClose)
    ui.OnEvent("BtnMinimize", "Click", "TitleBar_OnMinimize")
    ui.OnEvent("BtnMaximize", "Click", "TitleBar_OnMaximize")
}

; ======================================================================
; STANDARD HANDLERS
; ======================================================================

; Close: close WPF window and exit the AHK process
TitleBar_OnClose(state, ctrl, event) {
    global ui
    if IsObject(ui)
        ui.Close()
    ExitApp
}

; Minimize: send SC_MINIMIZE
TitleBar_OnMinimize(state, ctrl, event) {
    global ui
    PostMessage, 0x112, 0xF020, 0,, % "ahk_id " ui.wpfHwnd
}

; Maximize/Restore: toggle between Maximized and Normal state
TitleBar_OnMaximize(state, ctrl, event) {
    global ui
    WinGet, winState, MinMax, % "ahk_id " ui.wpfHwnd
    if (winState = 1) {  ; Currently maximized → restore
        PostMessage, 0x112, 0xF120, 0,, % "ahk_id " ui.wpfHwnd
        ui.Update("BtnMaximize", "Content", "□")
    } else {             ; Currently normal → maximize
        PostMessage, 0x112, 0xF030, 0,, % "ahk_id " ui.wpfHwnd
        ui.Update("BtnMaximize", "Content", "❐")
    }
}
