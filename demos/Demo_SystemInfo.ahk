#NoEnv
SetBatchLines, -1
#SingleInstance Force
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk

global ui := new XAMLGUI(A_ScriptDir "\SystemInfo.xaml")
global gTempFile := A_Temp "\sysinfo_output.txt"

InitTitleBar(ui, {title: "System Information", showTheme: true, showMin: true, showMax: false})
InitThemeManager(ui)
ApplyTheme("Navy")
ui.OnEvent("BtnTheme", "Click", "CycleTheme")
ui.OnEvent("BtnRefresh", "Click", "OnRefresh")

ui.Show()

; Run systeminfo and wait for completion
FileDelete, % gTempFile
ui.Update("TxtLoadingDetail", "Text", "Collecting system data...")
RunWait, %ComSpec% /c systeminfo > "%gTempFile%",, Hide

; Read and parse output (use OEM code page to match cmd.exe output)
oemCP := DllCall("GetOEMCP")
FileRead, rawOutput, *P%oemCP% %gTempFile%
if (ErrorLevel || rawOutput = "") {
    ui.Update("TxtLoadingDetail", "Text", "Error: could not read system information")
    return
}

ParseAndDisplay(rawOutput)
return

OnRefresh(state, ctrl, event) {
    global ui
    ui.Update("LoadingPanel", "Visibility", "Visible")
    ui.Update("ContentPanel", "Visibility", "Collapsed")
    ui.Update("TxtLoadingDetail", "Text", "Refreshing system data...")
    FileDelete, % gTempFile
    RunWait, %ComSpec% /c systeminfo > "%gTempFile%",, Hide
    oemCP := DllCall("GetOEMCP")
    FileRead, rawOutput, *P%oemCP% %gTempFile%
    if (ErrorLevel || rawOutput = "")
        return
    ParseAndDisplay(rawOutput)
}

ParseAndDisplay(raw) {
    global ui
    data := {}

    ; Normalize field names: map Spanish → English keys
    acc := Chr(0xED)  ; í
    aco := Chr(0xF3)  ; ó
    fieldMap := {"Nombre de host": "Host Name"
        , "Nombre del sistema operativo": "OS Name"
        , "Fabricante del sistema": "System Manufacturer"
        , "Modelo del sistema": "System Model"
        , "Procesadores": "Processor(s)"
        , "Dispositivo de arranque": "Boot Device"
        , "Directorio de Windows": "Windows Directory"
        , "Dominio": "Domain"
        , "Tarjetas de red": "Network Card(s)"}
    fieldMap["Versi" . aco . "n del sistema operativo"] := "OS Version"
    fieldMap["Memoria f" . acc . "sica total"] := "Total Physical Memory"
    fieldMap["Memoria f" . acc . "sica disponible"] := "Available Physical Memory"

    Loop, Parse, raw, `n, `r
    {
        line := A_LoopField
        if (line = "")
            continue
        colonPos := InStr(line, ":")
        if (colonPos > 0 && colonPos < 60) {
            field := Trim(SubStr(line, 1, colonPos - 1))
            value := Trim(SubStr(line, colonPos + 1))
            value := RegExReplace(value, "\s{2,}", " ")
            value := RegExReplace(value, "^\s+|\s+$", "")
            if fieldMap.HasKey(field)
                field := fieldMap[field]
            data[field] := value
        }
    }

    host    := GetVal(data, "Host Name", "N/A")
    os      := GetVal(data, "OS Name", "N/A")
    osVer   := GetVal(data, "OS Version", "N/A")
    mfg     := GetVal(data, "System Manufacturer", "N/A")
    model   := GetVal(data, "System Model", "N/A")
    cpu     := GetVal(data, "Processor(s)", "N/A")
    boot    := GetVal(data, "Boot Device", "N/A")
    winDir  := GetVal(data, "Windows Directory", "N/A")
    domain  := GetVal(data, "Domain", "N/A")
    netCards := GetVal(data, "Network Card(s)", "N/A")
    totalRaw := GetVal(data, "Total Physical Memory", "0")
    availRaw := GetVal(data, "Available Physical Memory", "0")

    ui.Update("TxtHostName", "Text", host)
    ui.Update("TxtOSName", "Text", os)
    ui.Update("TxtOSVersion", "Text", osVer)
    ui.Update("TxtManufacturer", "Text", mfg)
    ui.Update("TxtModel", "Text", model)
    ui.Update("TxtProcessor", "Text", cpu)
    ui.Update("TxtBootDevice", "Text", boot)
    ui.Update("TxtWindowsDir", "Text", winDir)
    ui.Update("TxtDomain", "Text", domain)
    ui.Update("TxtNetworkCards", "Text", netCards)

    totalMB := ParseMB(totalRaw)
    availMB := ParseMB(availRaw)
    usedMB := totalMB - availMB
    ui.Update("TxtTotalRAM", "Text", FormatMB(totalMB))
    ui.Update("TxtAvailableRAM", "Text", FormatMB(availMB))
    ui.Update("TxtUsedRAM", "Text", FormatMB(usedMB))

    ; Collect remaining fields for the extra info card
    knownKeys := "Host Name|OS Name|OS Version|System Manufacturer|System Model|Processor(s)|Boot Device|Windows Directory|Domain|Network Card(s)|Total Physical Memory|Available Physical Memory"
    extra := ""
    for key, val in data
    {
        if !InStr("|" knownKeys "|", "|" key "|")
        {
            val := RegExReplace(val, "\s{2,}", " ")
            val := RegExReplace(val, "^\s+|\s+$", "")
            if (val != "" && val != "N/D")
                extra .= key ": " val "`n"
        }
    }
    if (extra = "")
        extra := "No additional system information available."
    ui.Update("TxtExtraInfo", "Text", RTrim(extra, "`n"))

    ui.Update("LoadingPanel", "Visibility", "Collapsed")
    ui.Update("ContentPanel", "Visibility", "Visible")

    FormatTime, now,, yyyy-MM-dd HH:mm:ss
    ui.Update("TxtStatus", "Text", "Last updated: " now)
}

GetVal(data, key, default) {
    return data.HasKey(key) ? data[key] : default
}

ParseMB(str) {
    if (str = "")
        return 0
    numStr := RegExReplace(str, "[^\d]", "")
    return numStr + 0
}

FormatMB(mb) {
    if (mb >= 1024)
        return Format("{1:.1f} GB", mb / 1024)
    return mb " MB"
}