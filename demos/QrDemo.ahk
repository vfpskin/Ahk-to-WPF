#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\QrDemo.xaml")
global currentText := ""

ui.OnEvent("TxtInput",    "TextChanged", "OnTextChanged")
ui.OnEvent("BtnQR",       "Click", "OnQR")
ui.OnEvent("BtnCode128",  "Click", "OnCode128")
ui.OnEvent("BtnCode39",   "Click", "OnCode39")
ui.OnEvent("BtnEAN13",    "Click", "OnEAN13")
ui.OnEvent("BtnExportPNG","Click", "OnExportPNG")
ui.OnEvent("BtnExportJPG","Click", "OnExportJPG")
ui.OnEvent("BtnExportBMP","Click", "OnExportBMP")
ui.OnEvent("BtnClear",    "Click", "OnClear")
ui.OnEvent("BtnClose",    "Click", "OnClose")

; Initial encode
currentText := "https://github.com/bblanchon/pdfium-binaries"
ui.Update("QrDisplay", "Format", "QR_CODE")
ui.Update("QrDisplay", "Encode", currentText)
ui.Update("LblStatus", "Text", "Format: QR_CODE - Type text, then Save PNG/JPG/BMP to export")

ui.Show()
return

; Auto-encode on text change
OnTextChanged(state, ctrl, event)
{
    global ui, currentText
    currentText := state["TxtInput"]
    if (currentText != "")
    {
        ui.Update("QrDisplay", "Encode", currentText)
        ui.Update("LblStatus", "Text", "Encoded " . StrLen(currentText) . " chars")
    }
}

; Format buttons
OnQR(state, ctrl, event)
{
    global ui, currentText
    SetFormat("QR_CODE")
}

OnCode128(state, ctrl, event)
{
    global ui, currentText
    SetFormat("CODE_128")
}

OnCode39(state, ctrl, event)
{
    global ui, currentText
    SetFormat("CODE_39")
}

OnEAN13(state, ctrl, event)
{
    global ui, currentText
    SetFormat("EAN_13")
}

; Export buttons
OnExportPNG(state, ctrl, event)
{
    global ui, currentText
    ExportFile("PNG")
}

OnExportJPG(state, ctrl, event)
{
    global ui, currentText
    ExportFile("JPG")
}

OnExportBMP(state, ctrl, event)
{
    global ui, currentText
    ExportFile("BMP")
}

; Helpers
SetFormat(fmt)
{
    global ui, currentText
    ui.Update("QrDisplay", "Format", fmt)
    txt := currentText
    if (txt = "")
        txt := "Hello"
    ui.Update("QrDisplay", "Encode", txt)
    ui.Update("LblStatus", "Text", "Format: " . fmt)
}

ExportFile(fmt)
{
    global ui, currentText
    if (currentText = "")
    {
        ui.Update("LblStatus", "Text", "Nothing to export - type some text first")
        return
    }
    ; Build filename with timestamp: QR_YYYYMMDD_HHMMSS.fmt
    FormatTime now, , yyyyMMdd_HHmmss
    ext := fmt
    fileName := A_ScriptDir . "\QR_" . now . "." . ext
    ui.Update("QrDisplay", "Export", fmt . "|" . fileName)
    ui.Update("LblStatus", "Text", "Exported: " . fileName)
}

OnClear(state, ctrl, event)
{
    global ui, currentText
    currentText := ""
    ui.Update("QrDisplay", "Clear", "")
    ui.Update("TxtInput", "Text", "")
    ui.Update("LblStatus", "Text", "Cleared")
}

OnClose(state, ctrl, event)
{
    ui.Close()
    ExitApp
}
