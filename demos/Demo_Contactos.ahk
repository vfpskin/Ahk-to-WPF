#NoEnv
SetBatchLines, -1
#SingleInstance Force
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk

; ======================================================================
; DEMO: Contact List
; ======================================================================
global ui := new XAMLGUI("Demo_Contactos.xaml")

; Global Variables
global Contacts    := []    ; Array of objects {Name, Phone, Email}
global SelectedIdx  := 0     ; 1-based index of the selected item
global EditingIdx   := 0     ; Contact index being edited (0 = not editing)
global ConfigFile   := A_ScriptDir "\contacts_data.ini"

InitThemeManager(ui)
InitTitleBar(ui, {title: "Contact List", showTheme: true, onClose: "BtnClose_Click"})
LoadData() ; Load saved contacts and theme

; Register events
ui.OnEvent("BtnTheme",      "Click",            "CycleTheme")
ui.OnEvent("BtnAdd",    "Click",            "Add_Click")
ui.OnEvent("BtnDelete",   "Click",            "Delete_Click")
ui.OnEvent("BtnEdit",     "Click",            "Edit_Click")
ui.OnEvent("ContactList","SelectionChanged", "List_SelectionChanged")

; Enter key on input fields
ui.OnEvent("TxtName",   "Enter", "Field_Enter")
ui.OnEvent("TxtPhone", "Enter", "Field_Enter")
ui.OnEvent("TxtEmail",    "Enter", "Field_Enter")

; SweetAlert overlay events
ui.OnEvent("BtnSA_OK",   "Click", "SA_OnClick")
ui.OnEvent("BtnSA_Yes",  "Click", "SA_OnClick")
ui.OnEvent("BtnSA_No",   "Click", "SA_OnClick")

ui.Show()
return

; ======================================================================
; DATA PERSISTENCE
; ======================================================================
SaveData()
{
    global Contacts, ConfigFile
    FileDelete, %ConfigFile%
    FileAppend, % GetCurrentTheme(), %ConfigFile%
    FileDelete, %ConfigFile%_contacts.txt
    for i, c in Contacts
        FileAppend, % c.Name "|" c.Phone "|" c.Email "`n", %ConfigFile%_contacts.txt
}

LoadData()
{
    global Contacts, ConfigFile
    FileRead, theme, %ConfigFile%
    theme := Trim(theme)
    if (theme = "")
        theme := "Navy"
    ApplyTheme(theme)
    if (FileExist(ConfigFile "_contacts.txt")) {
        Loop, Read, %ConfigFile%_contacts.txt
        {
            StringSplit, campos, A_LoopReadLine, |
            Contacts.Push({Name: campos1, Phone: campos2, Email: campos3})
        }
        RebuildList()
        UpdateCounter()
    }
}

; ======================================================================
; CLOSE
; ======================================================================
BtnClose_Click(state, ctrl, event)
{
    global ui
    SaveData()
    ui.Close()
    ExitApp
}

; ======================================================================
; ENTER IN FIELDS — Advance focus or Add
; ======================================================================
Field_Enter(state, ctrl, event)
{
    global ui
    if (ctrl = "TxtName")
        ui.Focus("TxtPhone")
    else if (ctrl = "TxtPhone")
        ui.Focus("TxtEmail")
    else if (ctrl = "TxtEmail")
        Add_Click(state, "BtnAdd", "Click")
}

; ======================================================================
; ADD / SAVE CONTACT
; ======================================================================
Add_Click(state, ctrl, event)
{
    global ui, Contacts, EditingIdx, SelectedIdx
    name := Trim(state["TxtName"]), phone := Trim(state["TxtPhone"]), email := Trim(state["TxtEmail"])
    if (name = "") {
        ShowOverlayAlert("Error", "The Name field is required.", "error")
        return
    }
    if (EditingIdx > 0) {
        Contacts[EditingIdx] := {Name: name, Phone: phone, Email: email}
        EditingIdx := 0
        ui.Update("BtnAdd", "Content", "+ Add")
    } else
        Contacts.Push({Name: name, Phone: phone, Email: email})
    RebuildList()
    ui.Update("TxtName", "Text", ""), ui.Update("TxtPhone", "Text", ""), ui.Update("TxtEmail", "Text", "")
    ui.Focus("TxtName"), SelectedIdx := 0
    ui.Update("BtnEdit", "IsEnabled", "False"), ui.Update("BtnDelete", "IsEnabled", "False")
    UpdateCounter()
}

; ======================================================================
; LISTVIEW SELECTION
; ======================================================================
List_SelectionChanged(state, ctrl, event)
{
    global ui, SelectedIdx, EditingIdx
    raw := state["ContactList"]
    if (raw = "")
        SelectedIdx := 0
    else {
        StringSplit, campos, raw, |
        SelectedIdx := campos1 + 0
    }
    if (EditingIdx > 0)
        return
    ui.Update("BtnEdit", "IsEnabled", (SelectedIdx > 0))
    ui.Update("BtnDelete", "IsEnabled", (SelectedIdx > 0))
}

; ======================================================================
; EDIT CONTACT
; ======================================================================
Edit_Click(state, ctrl, event)
{
    global Contacts, SelectedIdx, ui, EditingIdx
    if (SelectedIdx < 1 || SelectedIdx > Contacts.Length())
        return
    c := Contacts[SelectedIdx]
    ui.Update("TxtName", "Text", c.Name), ui.Update("TxtPhone", "Text", c.Phone), ui.Update("TxtEmail", "Text", c.Email)
    EditingIdx := SelectedIdx
    ui.Update("BtnAdd", "Content", "Save Changes")
    ui.Update("BtnEdit", "IsEnabled", "False"), ui.Update("BtnDelete", "IsEnabled", "False")
}

; ======================================================================
; DELETE CONTACT
; ======================================================================
Delete_Click(state, ctrl, event)
{
    global ui, Contacts, SelectedIdx
    if (SelectedIdx < 1 || SelectedIdx > Contacts.Length())
        return
    ShowOverlayConfirm("Confirm Deletion", "Delete """ Contacts[SelectedIdx].Name """?", "ConfirmDelete")
}

ConfirmDelete()
{
    global ui, Contacts, SelectedIdx
    Contacts.Remove(SelectedIdx)
    SelectedIdx := 0
    RebuildList()
    ui.Update("BtnEdit", "IsEnabled", "False"), ui.Update("BtnDelete", "IsEnabled", "False")
    UpdateCounter()
}

; ======================================================================
; SWEET ALERT OVERLAY
; ======================================================================
global SA_Callback := ""
ShowOverlayAlert(title, message, iconType:="info", callback:="")
{
    global ui, SA_Callback
    SA_Callback := callback
    ui.Update("SA_TxtTitle", "Text", title), ui.Update("SA_TxtMessage", "Text", message)
    ui.Update("SA_IcoInfo", "Visibility", (iconType="info"?"Visible":"Collapsed"))
    ui.Update("SA_IcoSuccess", "Visibility", (iconType="success"?"Visible":"Collapsed"))
    ui.Update("SA_IcoError", "Visibility", (iconType="error"?"Visible":"Collapsed"))
    ui.Update("SA_IcoWarning", "Visibility", (iconType="warning"?"Visible":"Collapsed"))
    ui.Update("BtnSA_OK", "Visibility", "Visible"), ui.Update("BtnSA_Yes", "Visibility", "Collapsed"), ui.Update("BtnSA_No", "Visibility", "Collapsed")
    ui.Update("SweetAlertOverlay", "Visibility", "Visible"), ui.Focus("BtnSA_OK")
}

ShowOverlayConfirm(title, message, callbackYes:="")
{
    global ui, SA_Callback
    SA_Callback := callbackYes
    ui.Update("SA_TxtTitle", "Text", title), ui.Update("SA_TxtMessage", "Text", message)
    ui.Update("SA_IcoInfo", "Visibility", "Collapsed"), ui.Update("SA_IcoSuccess", "Visibility", "Collapsed"), ui.Update("SA_IcoError", "Visibility", "Collapsed"), ui.Update("SA_IcoWarning", "Visibility", "Visible")
    ui.Update("BtnSA_OK", "Visibility", "Collapsed"), ui.Update("BtnSA_Yes", "Visibility", "Visible"), ui.Update("BtnSA_No", "Visibility", "Visible")
    ui.Update("SweetAlertOverlay", "Visibility", "Visible"), ui.Focus("BtnSA_Yes")
}

SA_OnClick(state, ctrl, event)
{
    global ui, SA_Callback
    ui.Update("SweetAlertOverlay", "Visibility", "Collapsed")
    if (ctrl = "BtnSA_Yes" && SA_Callback != "" && IsFunc(SA_Callback))
        %SA_Callback%()
}

; ======================================================================
; HELPERS
; ======================================================================
RebuildList()
{
    global ui, Contacts
    ui.Update("ContactList", "ClearItems", "")
    for i, c in Contacts
        ui.Update("ContactList", "AddItem", i . "|" . c.Name . "|" . c.Phone . "|" . c.Email)
}

UpdateCounter()
{
    global ui, Contacts
    n := Contacts.Length()
    ui.Update("LblTotal", "Text", (n = 1 ? "1 contact" : n . " contacts"))
}
