#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\OcrDemo.xaml")
global currentPath := ""
global ocrTextResult := ""
global ocrLangCode := "eng"

ui.OnEvent("BtnBrowse", "Click", "OnBrowse")
ui.OnEvent("BtnOcr", "Click", "OnOcr")
ui.OnEvent("BtnClear", "Click", "OnClear")
ui.OnEvent("BtnTranslate", "Click", "OnTranslate")
ui.OnEvent("OcrView", "OcrComplete", "OnOcrComplete")
ui.OnEvent("ImagePath", "TextChanged", "OnPathChanged")
ui.OnEvent("BtnClose", "Click", "OnClose")

ui.Show()
return

OnBrowse(state, ctrl, event)
{
    global ui, currentPath
    FileSelectFile path, 3, , Select image for OCR, Images (*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff)
    if (path != "")
    {
        ui.Update("ImagePath", "Text", path)
        currentPath := path
        ui.Update("BtnOcr", "IsEnabled", "True")
    }
}

OnOcr(state, ctrl, event)
{
    global ui, currentPath, ocrLangCode
    if (currentPath != "" && FileExist(currentPath))
    {
        langText := state["LangSelector"]
        ocrLangCode := "eng"
        if (langText = "Spanish")
            ocrLangCode := "spa"
        else if (langText = "English + Spanish")
            ocrLangCode := "eng+spa"
        else if (langText = "Spanish + English")
            ocrLangCode := "spa+eng"
        ui.Update("OcrView", "Lang", ocrLangCode)
        ui.Update("OcrView", "Image", currentPath)
        ui.Update("BtnOcr", "IsEnabled", "False")
        ui.Update("BtnOcr", "Content", "Working...")
    }
}

OnClear(state, ctrl, event)
{
    global ui, currentPath, ocrTextResult
    ui.Update("OcrView", "Clear", "")
    ui.Update("ImagePath", "Text", "")
    currentPath := ""
    ocrTextResult := ""
    ui.Update("BtnOcr", "IsEnabled", "False")
    ui.Update("BtnOcr", "Content", "Run OCR")
    ui.Update("BtnTranslate", "IsEnabled", "False")
}

OnTranslate(state, ctrl, event)
{
    global ocrTextResult, ocrLangCode
    if (ocrTextResult != "" && ocrTextResult != "(no text recognized)")
    {
        ; Get primary source language (first code before +)
    src := ocrLangCode
    plus := InStr(ocrLangCode, "+")
    if (plus > 0)
        src := SubStr(ocrLangCode, 1, plus - 1)
    encoded := UriEncode(ocrTextResult)
    Run "https://translate.google.com/?sl=" src "&tl=es&text=" encoded
    }
}

OnOcrComplete(state, ctrl, event)
{
    global ui, ocrTextResult
    ocrTextResult := state["OcrText"]
    ui.Update("BtnOcr", "IsEnabled", "True")
    ui.Update("BtnOcr", "Content", "Run OCR")
    if (ocrTextResult != "" && ocrTextResult != "(no text recognized)")
        ui.Update("BtnTranslate", "IsEnabled", "True")
}

OnPathChanged(state, ctrl, event)
{
    global ui, currentPath
    path := state["ImagePath"]
    if (path != "" && FileExist(path))
    {
        currentPath := path
        ui.Update("BtnOcr", "IsEnabled", "True")
    }
    else
    {
        ui.Update("BtnOcr", "IsEnabled", "False")
    }
}

OnClose(state, ctrl, event)
{
    ui.Close()
    ExitApp
}

UriEncode(str)
{
    VarSetCapacity(bin, StrPut(str, "UTF-8"))
    StrPut(str, &bin, "UTF-8")
    len := DllCall("WideCharToMultiByte", "int", 65001, "int", 0, "ptr", &bin, "int", -1, "ptr", 0, "int", 0)
    VarSetCapacity(utf8, len * 2)
    DllCall("WideCharToMultiByte", "int", 65001, "int", 0, "ptr", &bin, "int", -1, "str", utf8, "int", len * 2)
    out := ""
    loop parse, utf8
    {
        c := Asc(A_LoopField)
        if (c > 0x7F || c = 0x20 || InStr("`%&+,/:;=?@<>#%{}|\^~[]`'""", Chr(c)))
            out .= "%" Format("{:02X}", c)
        else
            out .= Chr(c)
    }
    return out
}
