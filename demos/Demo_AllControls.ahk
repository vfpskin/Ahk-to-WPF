#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\Demo_AllControls.xaml")

InitThemeManager(ui, ["Navy", "Dark", "Light", "Blue", "Green", "Purple", "Red", "Orange", "Teal"])
ApplyTheme("Navy")
ui.SetWindowProp("Background", "Transparent")

InitTitleBar(ui, {title: "All Controls Demo", showTheme: false, showMin: false, showMax: false})

; --- Events ---

; Title bar
ui.OnEvent("BtnTheme", "Click", "OnCycleTheme")
ui.OnEvent("BtnClose", "Click", "OnBtnClose")

; Tab 1: Buttons & Toggles
ui.OnEvent("TglFeature", "Checked", "OnToggleChanged")
ui.OnEvent("TglFeature", "Unchecked", "OnToggleChanged")
ui.OnEvent("BtnRepeat", "Click", "OnRepeatClick")
ui.OnEvent("ChkRemember", "Checked", "OnCheckChanged")
ui.OnEvent("ChkRemember", "Unchecked", "OnCheckChanged")
ui.OnEvent("RadioA", "Checked", "OnRadioChanged")
ui.OnEvent("RadioA", "Unchecked", "OnRadioChanged")
ui.OnEvent("RadioB", "Checked", "OnRadioChanged")
ui.OnEvent("RadioB", "Unchecked", "OnRadioChanged")
ui.OnEvent("RadioC", "Checked", "OnRadioChanged")
ui.OnEvent("RadioC", "Unchecked", "OnRadioChanged")

; Tab 2: Input & Text
ui.OnEvent("LinkGitHub", "Click", "OnLinkClick")
ui.OnEvent("TxtInput", "TextChanged", "OnTextChanged")
ui.OnEvent("PassInput", "TextChanged", "OnPassChanged")
ui.OnEvent("PassInput", "GotFocus", "OnPassFocus")
ui.OnEvent("PassInput", "LostFocus", "OnPassFocus")

; Tab 3: Tabs & Nav
ui.OnEvent("MainTabs", "TabChanged", "OnMainTabChanged")
ui.OnEvent("InnerTabs", "TabChanged", "OnInnerTabChanged")
ui.OnEvent("BtnPage1", "Click", "OnNavPage")
ui.OnEvent("BtnPage2", "Click", "OnNavPage")

; Tab 5: Dates
ui.OnEvent("DatePick", "DateChanged", "OnDateChanged")
ui.OnEvent("CalMain", "DateChanged", "OnCalendarDateChanged")

; Tab 4: Progress & Values
ui.OnEvent("SldValue", "ValueChanged", "OnSliderChanged")
ui.OnEvent("ScrValue", "ValueChanged", "OnScrollChanged")
ui.OnEvent("ScrVert", "ValueChanged", "OnScrollChanged")
ui.OnEvent("BtnProgSet", "Click", "OnProgressClick")
ui.OnEvent("BtnProgInc", "Click", "OnProgressClick")
ui.OnEvent("BtnProgDec", "Click", "OnProgressClick")

ui.Show()

; ═══════════════════════════════════════════════════════════
; HANDLERS
; ═══════════════════════════════════════════════════════════

OnCycleTheme(state, ctrl, event)
{
    CycleTheme(state, ctrl, event)
    global ui
    ui.SetWindowProp("Background", "Transparent")
    ui.Update("TxtLastAction", "Text", "Theme: " GetCurrentTheme())
}

OnBtnClose(state, ctrl, event)
{
    global ui
    ui.Close()
    ExitApp
}

; ── ToggleButton ──
OnToggleChanged(state, ctrl, event)
{
    global ui
    checked := state["TglFeature"]
    if (checked = "1")
    {
        ui.Update("TxtToggleState", "Text", "ON")
        ui.Update("TxtLastAction", "Text", "ToggleButton: ON  (AHK ← WPF: read IsChecked = True)")
    }
    else
    {
        ui.Update("TxtToggleState", "Text", "OFF")
        ui.Update("TxtLastAction", "Text", "ToggleButton: OFF  (AHK ← WPF: read IsChecked = False)")
    }
}

; ── RepeatButton ──
global g_repeatCount := 0
OnRepeatClick(state, ctrl, event)
{
    global ui, g_repeatCount
    g_repeatCount++
    ui.Update("TxtRepeatCount", "Text", "Count: " g_repeatCount)
    ui.Update("TxtLastAction", "Text", "RepeatButton: Click #" g_repeatCount "  (fires repeatedly while held)")
}

; ── CheckBox ──
OnCheckChanged(state, ctrl, event)
{
    global ui
    checked := state["ChkRemember"]
    if (checked = "1")
    {
        ui.Update("TxtCheckState", "Text", "Checked")
        ui.Update("TxtLastAction", "Text", "CheckBox: Checked  (AHK ← WPF: read IsChecked = True)")
    }
    else
    {
        ui.Update("TxtCheckState", "Text", "Unchecked")
        ui.Update("TxtLastAction", "Text", "CheckBox: Unchecked  (AHK ← WPF: read IsChecked = False)")
    }
}

; ── RadioButtons ──
OnRadioChanged(state, ctrl, event)
{
    global ui
    sel := ""
    if (state["RadioA"] = "1")
        sel := "Option A"
    else if (state["RadioB"] = "1")
        sel := "Option B"
    else if (state["RadioC"] = "1")
        sel := "Option C"
    ui.Update("TxtRadioState", "Text", "Selected: " sel)
    ui.Update("TxtLastAction", "Text", "RadioButton: " sel "  (AHK ← WPF: read all IsChecked)")
}

; ── Hyperlink (styled as Button) ──
OnLinkClick(state, ctrl, event)
{
    global ui
    ui.Update("TxtLastAction", "Text", "Hyperlink: https://github.com/vfpskin/Ahk-to-WPF  (open URL in browser via AHK)")
    Run, https://github.com/vfpskin/Ahk-to-WPF
}

; ── TextBox TextChanged ──
OnTextChanged(state, ctrl, event)
{
    global ui
    txt := state["TxtInput"]
    ui.Update("TxtLastAction", "Text", "TextBox: " txt "  (live via TextChanged)")
}

; ── PasswordBox ──
OnPassChanged(state, ctrl, event)
{
    global ui
    pass := state["PassInput"]
    len := StrLen(pass)
    dots := ""
    Loop, % len
        dots .= "&#x25CF;"
    if (len = 0)
        dots := "(empty)"
    ui.Update("TxtLastAction", "Text", "PasswordBox: " len " chars typed  (live via PasswordChanged)")
}

OnPassFocus(state, ctrl, event)
{
    global ui
    if (event = "GotFocus")
        ui.Update("TxtLastAction", "Text", "PasswordBox: focused")
    else
        ui.Update("TxtLastAction", "Text", "PasswordBox: lost focus")
}

; ── Main TabControl ──
OnMainTabChanged(state, ctrl, event)
{
    global ui
    idx := state["MainTabs"]
    names := ["Buttons & Toggles", "Input & Text", "Tabs & Nav", "Progress & Values", "Dates & Status"]
    tabName := "Tab #" idx
    if (idx + 0 >= 1 && idx + 0 <= names.Length())
        tabName := names[idx + 0]
    ui.Update("TxtLastAction", "Text", "MainTabs: " tabName "  (AHK ← WPF: read SelectedIndex = " idx ")")
}

; ── Inner TabControl (TabItem demo) ──
OnInnerTabChanged(state, ctrl, event)
{
    global ui
    idx := state["InnerTabs"]
    txt := "Selected: Page " idx
    ui.Update("TxtTabState", "Text", txt)
    ui.Update("TxtLastAction", "Text", "InnerTabs TabItem: " txt "  (TabChanged event from inner TabControl)")
}

; ── Page Navigation (toggle panels) ──
OnNavPage(state, ctrl, event)
{
    global ui
    if (ctrl = "BtnPage1")
    {
        ui.Update("PagePanel1", "Visibility", "Visible")
        ui.Update("PagePanel2", "Visibility", "Collapsed")
        ui.Update("TxtLastAction", "Text", "Page: Dashboard shown  (AHK → WPF: toggle Visibility)")
    }
    else
    {
        ui.Update("PagePanel1", "Visibility", "Collapsed")
        ui.Update("PagePanel2", "Visibility", "Visible")
        ui.Update("TxtLastAction", "Text", "Page: Reports shown  (AHK → WPF: toggle Visibility)")
    }
}

; ── Slider ──
OnSliderChanged(state, ctrl, event)
{
    global ui
    val := state["SldValue"]
    ui.Update("TxtSliderValue", "Text", val)
    ; Sync ProgressBar to slider value (AHK → WPF)
    ui.Update("ProgBar", "Value", val)
    ui.Update("TxtProgValue", "Text", val "%")
    ui.Update("TxtLastAction", "Text", "Slider: " val "  (AHK ← WPF: read Value; AHK → WPF: update ProgressBar + labels)")
}

; ── DatePicker ──
OnDateChanged(state, ctrl, event)
{
    global ui
    date := state["DatePick"]
    if (date = "")
        date := "(none)"
    ui.Update("TxtDateValue", "Text", date)
    ui.Update("StatusLeft", "Content", "DatePicker: " date)
    ui.Update("TxtLastAction", "Text", "DatePicker: " date "  (AHK ← WPF: read SelectedDate on DateChanged)")
}

; ── Calendar ──
OnCalendarDateChanged(state, ctrl, event)
{
    global ui
    date := state["CalMain"]
    if (date = "")
        date := "(none)"
    ui.Update("StatusRight", "Content", "Calendar: " date)
    ui.Update("TxtLastAction", "Text", "Calendar: " date "  (AHK ← WPF: read SelectedDate on SelectedDatesChanged)")
}

; ── ScrollBars (horizontal + vertical) → circle position ──
OnScrollChanged(state, ctrl, event)
{
    global ui
    val := state["ScrValue"]
    valV := state["ScrVert"]
    ui.Update("TxtScrollValue", "Text", "X:" val)
    ui.Update("TxtScrollVertValue", "Text", " Y:" valV)
    marginX := Round(val * 2.0)
    marginY := Round((100 - valV) * 2.0)
    if (marginX > 200)
        marginX := 200
    if (marginY > 200)
        marginY := 200
    if (marginY < 0)
        marginY := 0
    ui.Update("CircleDot", "Margin", marginX "," marginY ",0,0")
    ui.Update("TxtLastAction", "Text", "Circle at X:" marginX " Y:" marginY "  (H:" val " V:" valV ")")
}

; ── ProgressBar buttons ──
OnProgressClick(state, ctrl, event)
{
    global ui
    val := state["ProgBar"]
    if (ctrl = "BtnProgSet")
    {
        val := 75
    }
    else if (ctrl = "BtnProgInc")
    {
        val := val + 10
        if (val > 100)
            val := 100
    }
    else if (ctrl = "BtnProgDec")
    {
        val := val - 10
        if (val < 0)
            val := 0
    }
    ui.Update("ProgBar", "Value", val)
    ui.Update("TxtProgValue", "Text", val "%")
    ui.Update("TxtLastAction", "Text", "ProgressBar: " val "%  (AHK → WPF: set Value from button click)")
}