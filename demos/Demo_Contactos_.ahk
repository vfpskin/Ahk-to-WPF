#NoEnv
SetBatchLines, -1
#SingleInstance Force
#Include %A_ScriptDir%\..\XAMLGUI.ahk

; ======================================================================
; DEMO: Agenda de Contactos
; ======================================================================
global ui := new XAMLGUI("Demo_Contactos.xaml")

; Variables globales
global Contactos    := []   ; Array de objetos {Nombre, Telefono, Email}
global SelectedIdx  := 0    ; Indice 1-based del item seleccionado
global EditingIdx   := 0    ; Indice del contacto en edicion (0 = no editando)
global gThemeIndex  := 1

InitThemeCatalog()

; Registrar eventos
ui.OnEvent("BtnClose",      "Click",            "BtnClose_Click")
ui.OnEvent("BtnTheme",      "Click",            "ChangeTheme_Event")
ui.OnEvent("BtnAgregar",    "Click",            "Agregar_Click")
ui.OnEvent("BtnEliminar",   "Click",            "Eliminar_Click")
ui.OnEvent("BtnEditar",     "Click",            "Editar_Click")
ui.OnEvent("ListaContactos","SelectionChanged", "Lista_SelectionChanged")

; Tecla Enter en los campos
ui.OnEvent("TxtNombre",   "Enter", "Campo_Enter")
ui.OnEvent("TxtTelefono", "Enter", "Campo_Enter")
ui.OnEvent("TxtEmail",    "Enter", "Campo_Enter")

; Eventos SweetAlert overlay
ui.OnEvent("BtnSA_OK",   "Click", "SA_OnClick")
ui.OnEvent("BtnSA_Yes",  "Click", "SA_OnClick")
ui.OnEvent("BtnSA_No",   "Click", "SA_OnClick")

ui.Show()
;ApplyTheme("Navy")
return

; ======================================================================
; TEMAS
; ======================================================================
InitThemeCatalog()
{
    global gThemeMap, gThemeOrder

    gThemeOrder := ["Navy", "Oscuro", "Claro", "Azul", "Verde", "Morado", "Teal"]

    gThemeMap := {}

    gThemeMap["Navy"] := {base:"Dark"
        , WindowBg:"#0A1628", SidebarBg:"#0F1D32", Surface:"#112236", Surface2:"#1A3050"
        , Border:"#2A4A6B", Accent:"#1A78C2", AccentHover:"#1565A8", AccentGlow:"#2196F3"
        , TextPrimary:"#E5F0F7", TextSecondary:"#97BCE1", TextMuted:"#6B8FB5"
        , RowHover:"#152A45", ScrollThumb:"#2A4A6B"
        , Success:"#1A7A4A", SuccessHover:"#166040", Danger:"#C0392B", DangerHover:"#A93226"}

    gThemeMap["Oscuro"] := {base:"Dark"
        , WindowBg:"#1E1E1E", SidebarBg:"#0F172A", Surface:"#111827", Surface2:"#172033"
        , Border:"#404040", Accent:"#5B9BD5", AccentHover:"#4A87C0", AccentGlow:"#7CB9E8"
        , TextPrimary:"#F0F0F0", TextSecondary:"#AAAAAA", TextMuted:"#64748B"
        , RowHover:"#1F2937", ScrollThumb:"#4B5563"
        , Success:"#22C55E", SuccessHover:"#16A34A", Danger:"#EF4444", DangerHover:"#DC2626"}

    gThemeMap["Claro"] := {base:"Light"
        , WindowBg:"#F4F4F4", SidebarBg:"#FFFFFF", Surface:"#FFFFFF", Surface2:"#F3F4F6"
        , Border:"#DCDCDC", Accent:"#2E6DA4", AccentHover:"#245A8A", AccentGlow:"#3B82F6"
        , TextPrimary:"#1A1A1A", TextSecondary:"#666666", TextMuted:"#94A3B8"
        , RowHover:"#E5E7EB", ScrollThumb:"#CBD5E1"
        , Success:"#16A34A", SuccessHover:"#15803D", Danger:"#DC2626", DangerHover:"#B91C1C"}

    gThemeMap["Azul"] := {base:"Blue"
        , WindowBg:"#D6EAF8", SidebarBg:"#DCEFFC", Surface:"#F7FBFF", Surface2:"#EAF3FF"
        , Border:"#AED6F1", Accent:"#0078D4", AccentHover:"#005A9E", AccentGlow:"#3B82F6"
        , TextPrimary:"#0D1117", TextSecondary:"#2471A3", TextMuted:"#5B6B7A"
        , RowHover:"#DBEAFE", ScrollThumb:"#93C5FD"
        , Success:"#059669", SuccessHover:"#047857", Danger:"#DC2626", DangerHover:"#B91C1C"}

    gThemeMap["Verde"] := {base:"Green"
        , WindowBg:"#D5F5E3", SidebarBg:"#EAFBF1", Surface:"#F4FFF8", Surface2:"#E1F9EB"
        , Border:"#A9DFBF", Accent:"#27AE60", AccentHover:"#1E8449", AccentGlow:"#34D399"
        , TextPrimary:"#0D1117", TextSecondary:"#1E8449", TextMuted:"#5F7C6A"
        , RowHover:"#D1FAE5", ScrollThumb:"#6EE7B7"
        , Success:"#16A34A", SuccessHover:"#15803D", Danger:"#DC2626", DangerHover:"#B91C1C"}

    gThemeMap["Morado"] := {base:"Purple"
        , WindowBg:"#E8DAEF", SidebarBg:"#F5EEF8", Surface:"#FBF7FD", Surface2:"#F0E6F6"
        , Border:"#D7BDE2", Accent:"#8E44AD", AccentHover:"#7D3C98", AccentGlow:"#A855F7"
        , TextPrimary:"#0D1117", TextSecondary:"#7D3C98", TextMuted:"#6B7280"
        , RowHover:"#F3E8FF", ScrollThumb:"#C4B5FD"
        , Success:"#16A34A", SuccessHover:"#15803D", Danger:"#DC2626", DangerHover:"#B91C1C"}

    gThemeMap["Teal"] := {base:"Teal"
        , WindowBg:"#D1F2EB", SidebarBg:"#E6FFFB", Surface:"#F4FFFD", Surface2:"#DDF7F3"
        , Border:"#A2D9CE", Accent:"#17A589", AccentHover:"#148F77", AccentGlow:"#2DD4BF"
        , TextPrimary:"#0D1117", TextSecondary:"#148F77", TextMuted:"#4B5563"
        , RowHover:"#CCFBF1", ScrollThumb:"#5EEAD4"
        , Success:"#059669", SuccessHover:"#047857", Danger:"#DC2626", DangerHover:"#B91C1C"}
}

ApplyTheme(label)
{
    global ui, gThemeMap, gThemeIndex, gThemeOrder

    if (!gThemeMap.HasKey(label))
        label := "Navy"

    Loop, % gThemeOrder.Length()
    {
        if (gThemeOrder[A_Index] = label)
        {
            gThemeIndex := A_Index
            break
        }
    }

    tema := gThemeMap[label]
    ui.SetTheme(tema.base)

    for key, color in tema
    {
        if (key = "base")
            continue
        ui.SetResource(key, color)
    }

    ui.SetWindowProp("Background", tema.WindowBg)
    ui.Update("BtnTheme", "Content", label)
}

ChangeTheme_Event(state, ctrl, event)
{
    global gThemeIndex, gThemeOrder

    gThemeIndex++
    if (gThemeIndex > gThemeOrder.Length())
        gThemeIndex := 1

    ApplyTheme(gThemeOrder[gThemeIndex])
}

; ======================================================================
; CERRAR
; ======================================================================
BtnClose_Click(state, ctrl, event)
{
    global ui
    ui.Close()
    ExitApp
}

; ======================================================================
; ENTER EN CAMPOS — avanza foco o agrega
; ======================================================================
Campo_Enter(state, ctrl, event)
{
    global ui
    if (ctrl = "TxtNombre")
        ui.Focus("TxtTelefono")
    else if (ctrl = "TxtTelefono")
        ui.Focus("TxtEmail")
    else if (ctrl = "TxtEmail")
        Agregar_Click(state, "BtnAgregar", "Click")
}

; ======================================================================
; AGREGAR / GUARDAR CONTACTO
; ======================================================================
Agregar_Click(state, ctrl, event)
{
    global ui, Contactos, EditingIdx, SelectedIdx

    nombre   := Trim(state["TxtNombre"])
    telefono := Trim(state["TxtTelefono"])
    email    := Trim(state["TxtEmail"])

    if (nombre = "")
    {
        ShowOverlayAlert("Error", "El campo Nombre es obligatorio.", "error")
        return
    }

    if (EditingIdx > 0)
    {
        ; --- Modo edición: actualizar registro existente ---
        Contactos[EditingIdx].Nombre   := nombre
        Contactos[EditingIdx].Telefono := telefono
        Contactos[EditingIdx].Email    := email

        ; Reset editing state
        EditingIdx := 0
        ui.Update("BtnAgregar", "Content", "+ Agregar")
    }
    else
    {
        ; --- Modo agregar: nuevo registro ---
        contacto := {Nombre: nombre, Telefono: telefono, Email: email}
        Contactos.Push(contacto)
    }

    ; Refrescar lista completa
    ReconstruirLista()

    ; Limpiar campos
    ui.Update("TxtNombre",   "Text", "")
    ui.Update("TxtTelefono", "Text", "")
    ui.Update("TxtEmail",    "Text", "")
    ui.Focus("TxtNombre")

    ; Reset selection
    SelectedIdx := 0
    ui.Update("BtnEditar",   "IsEnabled", "False")
    ui.Update("BtnEliminar", "IsEnabled", "False")

    ActualizarContador()
}

; ======================================================================
; SELECCION EN LISTVIEW
; ======================================================================
Lista_SelectionChanged(state, ctrl, event)
{
    global ui, SelectedIdx, EditingIdx

    ; state["ListaContactos"] devuelve la fila completa como "idx|nombre|tel|email"
    ; Necesitamos extraer el primer campo (el número de índice)
    raw := state["ListaContactos"]
    if (raw = "")
    {
        SelectedIdx := 0
    }
    else
    {
        ; Extraer el primer campo antes del primer pipe
        StringSplit, campos, raw, |
        SelectedIdx := campos1 + 0   ; Convertir a número
    }

    ; Solo habilitar botones si NO estamos en modo edición
    if (EditingIdx > 0)
        return

    if (SelectedIdx > 0)
    {
        ui.Update("BtnEditar",   "IsEnabled", "True")
        ui.Update("BtnEliminar", "IsEnabled", "True")
    }
    else
    {
        ui.Update("BtnEditar",   "IsEnabled", "False")
        ui.Update("BtnEliminar", "IsEnabled", "False")
    }
}

; ======================================================================
; EDITAR CONTACTO — cargar datos en los TextBox existentes
; ======================================================================
Editar_Click(state, ctrl, event)
{
    global Contactos, SelectedIdx, ui, EditingIdx

    if (SelectedIdx < 1 || SelectedIdx > Contactos.Length())
        return

    ; Cargar datos del contacto seleccionado en los TextBox
    c := Contactos[SelectedIdx]
    ui.Update("TxtNombre",   "Text", c.Nombre)
    ui.Update("TxtTelefono", "Text", c.Telefono)
    ui.Update("TxtEmail",    "Text", c.Email)

    ; Preparar modo edición
    EditingIdx := SelectedIdx
    ui.Update("BtnAgregar", "Content", "Guardar Cambios")

    ; Desactivar botones mientras se edita
    ui.Update("BtnEditar",   "IsEnabled", "False")
    ui.Update("BtnEliminar", "IsEnabled", "False")
}

; ======================================================================
; ELIMINAR CONTACTO
; ======================================================================
Eliminar_Click(state, ctrl, event)
{
    global ui, Contactos, SelectedIdx

    if (SelectedIdx < 1 || SelectedIdx > Contactos.Length())
        return

    nombre := Contactos[SelectedIdx].Nombre
    ShowOverlayConfirm("Confirmar eliminacion"
        , "Eliminar a """ nombre """?"
        , "ConfirmarEliminar")
}

ConfirmarEliminar()
{
    global ui, Contactos, SelectedIdx

    if (SelectedIdx < 1 || SelectedIdx > Contactos.Length())
        return

    ; Eliminar del array (Remove re-indexa en AHK v1)
    Contactos.Remove(SelectedIdx)
    SelectedIdx := 0

    ; Reconstruir ListView completo
    ReconstruirLista()

    ; Deshabilitar botones
    ui.Update("BtnEditar",   "IsEnabled", "False")
    ui.Update("BtnEliminar", "IsEnabled", "False")

    ActualizarContador()
}

; ======================================================================
; SWEET ALERT OVERLAY
; ======================================================================
global SA_Callback := ""

ShowOverlayAlert(title, message, iconType:="info", callback:="")
{
    global ui, SA_Callback
    SA_Callback := callback

    ui.Update("SA_TxtTitle", "Text", title)
    ui.Update("SA_TxtMessage", "Text", message)

    ui.Update("SA_IcoInfo", "Visibility", "Collapsed")
    ui.Update("SA_IcoSuccess", "Visibility", "Collapsed")
    ui.Update("SA_IcoError", "Visibility", "Collapsed")
    ui.Update("SA_IcoWarning", "Visibility", "Collapsed")

    if (iconType = "info")
        ui.Update("SA_IcoInfo", "Visibility", "Visible")
    else if (iconType = "success")
        ui.Update("SA_IcoSuccess", "Visibility", "Visible")
    else if (iconType = "error")
        ui.Update("SA_IcoError", "Visibility", "Visible")
    else if (iconType = "warning")
        ui.Update("SA_IcoWarning", "Visibility", "Visible")

    ui.Update("BtnSA_OK", "Visibility", "Visible")
    ui.Update("BtnSA_Yes", "Visibility", "Collapsed")
    ui.Update("BtnSA_No", "Visibility", "Collapsed")
    ui.Update("SweetAlertOverlay", "Visibility", "Visible")
    ui.Focus("BtnSA_OK")
}

ShowOverlayConfirm(title, message, callbackYes:="")
{
    global ui, SA_Callback
    SA_Callback := callbackYes

    ui.Update("SA_TxtTitle", "Text", title)
    ui.Update("SA_TxtMessage", "Text", message)

    ui.Update("SA_IcoInfo", "Visibility", "Collapsed")
    ui.Update("SA_IcoSuccess", "Visibility", "Collapsed")
    ui.Update("SA_IcoError", "Visibility", "Collapsed")
    ui.Update("SA_IcoWarning", "Visibility", "Visible")

    ui.Update("BtnSA_OK", "Visibility", "Collapsed")
    ui.Update("BtnSA_Yes", "Visibility", "Visible")
    ui.Update("BtnSA_No", "Visibility", "Visible")
    ui.Update("SweetAlertOverlay", "Visibility", "Visible")
    ui.Focus("BtnSA_Yes")
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

ReconstruirLista()
{
    global ui, Contactos

    ; Limpiar ListView
    ui.Update("ListaContactos", "ClearItems", "")

    ; Volver a insertar todos con numero correlativo
    for i, c in Contactos
    {
        sleep, 50
        ui.Update("ListaContactos", "AddItem", i . "|" . c.Nombre . "|" . c.Telefono . "|" . c.Email)
    }

    ; Resetear seleccion
    ui.Update("BtnEditar",   "IsEnabled", "False")
    ui.Update("BtnEliminar", "IsEnabled", "False")
}

ActualizarContador()
{
    global ui, Contactos
    n := Contactos.Length()
    txt := (n = 1) ? "1 contact" : n . " contacts"
    ui.Update("LblTotal", "Text", txt)
}
