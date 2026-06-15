; ═══════════════════════════════════════════════════════════════════════════
; XAMLGUI.ahk  -  Motor WPF para AutoHotkey 1.1
; ═══════════════════════════════════════════════════════════════════════════
;
; MÉTODOS DISPONIBLES:
;
;   new XAMLGUI(xaml, exePath := "")
;       Crea una nueva instancia. Carga el XAML (string o ruta con FILE:).
;
;   .Show()
;       Lanza el proceso WPF_Runner.exe y muestra la ventana.
;
;   .OnEvent(ctrlName, eventName, callback)
;       Registra un callback AHK para un evento de control WPF.
;       Eventos WPF habituales: Click, TextChanged, GotFocus, LostFocus,
;       SelectionChanged, Click, MouseDoubleClick, RightClick,
;       Checked, Unchecked, ValueChanged, TabChanged, Enter.
;       ListView: Click, MouseDoubleClick, RightClick, Enter, SelectionChanged.
;       DataGrid: Click, MouseDoubleClick, RightClick, Enter, SelectionChanged,
;       SelectedCellsChanged, CurrentCellChanged, BeginningEdit,
;       CellEditEnding, RowEditEnding.
;       Enter: se dispara al pulsar Enter con el foco en Button, TextBox o PasswordBox.
;       En TextBox con AcceptsReturn="True" no se envía (Enter = nueva línea).
;
;   .Update(ctrlName, propName, value)
;       Actualiza cualquier propiedad de un control WPF.
;       Propiedades soportadas: Text, Content, IsEnabled, IsChecked, Visibility,
;       Value, SelectedIndex, AddItem, ClearItems, RemoveSelected,
;       UpdateSelected, UpdateRow, UpdateCell, DeleteRow, ScrollIntoView,
;       SetRowStyle, SetCellStyle,
;       Background, Foreground, BorderBrush, BorderThickness,
;       FontSize, FontWeight, Opacity, Width, Height, ToolTip.
;
;   .SetColor(ctrlName, prop, colorValue)
;       Atajo para cambiar color/estilo de un control individual.
;       Ej: ui.SetColor("BtnEnviar", "Background", "#27AE60")
;
;   .SetResource(resourceKey, colorValue)
;       Actualiza un DynamicResource en Window.Resources.
;       Todos los controles que usen {DynamicResource key} se actualizan.
;       Ej: ui.SetResource("Accent", "#E74C3C")
;           ui.SetResource("BgCard", "#2D2D2D")
;           ui.SetResource("TextPrimary", "#F0F0F0")
;
;   .SetTheme(themeName)
;       Aplica un tema predefinido completo. Cambia todos los recursos.
;       Temas: Light, Dark, Blue, Green, Purple, Red, Orange, Teal
;       Ej: ui.SetTheme("Dark")
;
;   .SetWindowProp(prop, value)
;       Modifica una propiedad de la ventana principal.
;       Props: Background, Title, Opacity, Width, Height
;       Ej: ui.SetWindowProp("Title", "Mi App - Tema Dark")
;           ui.SetWindowProp("Background", "#1E1E1E")
;
;   .Focus(ctrlName)
;       Lleva el foco a un control WPF.
;       Ej: ui.Focus("TxtPass")
;           ui.Focus("BtnLogin")
;
;   .Close()
;       Cierra la ventana WPF.
;
; ═══════════════════════════════════════════════════════════════════════════

#Requires AutoHotkey 1.1

class XAMLGUI
{
    static _instances := ""
    static _msgHooked := false

    ; ─────────────────────────────────────────────────────────────────────
    ; CONSTRUCTOR
    ; ─────────────────────────────────────────────────────────────────────

    __New(xaml := "", exePath := "")
    {
        ; Inicializar contenedor global
        if !IsObject(XAMLGUI._instances)
            XAMLGUI._instances := Object()

        this.id := "WPF_" . A_TickCount . "_" . XAMLGUI_Rand(1000,9999)

        this.xaml := xaml

        if (exePath = "")
            ;this.exePath := A_ScriptDir "\\WPF_Runner.exe"
            this.exePath := A_ScriptDir "\..\WPF_Runner.exe"
        else
            this.exePath := exePath

        this.events   := Object()
        this.wpfHwnd  := 0
        this.pid      := 0

        ; Crear GUI receptora oculta
        _id := this.id

        Gui, % "XRECV_" _id ":New", +HwndXRecvHwnd -Caption +ToolWindow
        Gui, % "XRECV_" _id ":Show", x-32000 y-32000 w1 h1 NA

        WinSetTitle, % "ahk_id " XRecvHwnd,, % "AhkWpfReceiver_" _id

        this.receiverHwnd := XRecvHwnd
        FileAppend, % "XAMLGUI: Created receiver window " XRecvHwnd " id=" _id "`n", % A_Temp "\XAMLGUI_Debug.log"

        ; Permitir WM_COPYDATA
        DllCall("ChangeWindowMessageFilter", "UInt", 0x004A, "UInt", 1)

        ; Hook global una sola vez
        if (!XAMLGUI._msgHooked)
        {
            OnMessage(0x004A, "XAMLGUI_OnWmCopyData")
            XAMLGUI._msgHooked := true
            FileAppend, % "XAMLGUI: Hooked WM_COPYDATA" "`n", % A_Temp "\XAMLGUI_Debug.log"
        }

        ; Registrar instancia
        XAMLGUI._instances[this.id] := this
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; REGISTRAR EVENTO
    ; ─────────────────────────────────────────────────────────────────────

    OnEvent(ctrlName, eventName, callback)
    {
        if !this.events.HasKey(ctrlName)
            this.events[ctrlName] := Object()

        this.events[ctrlName][eventName] := callback
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; MOSTRAR VENTANA
    ; ─────────────────────────────────────────────────────────────────────

    Show()
    {
        if !FileExist(this.exePath)
        {
            _msg := "WPF_Runner.exe not found"
            . "`n`nWPF_Runner.exe is required to run AHK + WPF demos."
            . "`n`nExpected location:"
            . "`n" this.exePath
            . "`n`nHow to get it:"
            . "`n`n1) Compile it manually:"
            . "`n   Run compile_WPF_Runner.bat"
            . "`n   (requires .NET Framework 4.x, included with Windows)"
            . "`n`n2) Download from GitHub Releases:"
            . "`n   https://github.com/vfpskin/Ahk-to-WPF/releases"
            . "`n`nPlace WPF_Runner.exe in the project root next to XAMLGUI.ahk."
            MsgBox, 16, Error, % _msg
            return false
        }

        _tmpXaml := ""
        _useFileArg := false

        ; Soportar FILE:ruta y también una ruta .xaml directa
        if (SubStr(this.xaml, 1, 5) = "FILE:")
        {
            _srcXaml := SubStr(this.xaml, 6)
        }
        else if (FileExist(this.xaml) && RegExMatch(this.xaml, "i)\.xaml$"))
        {
            _srcXaml := this.xaml
        }
        else
        {
            _srcXaml := ""
        }

        if (_srcXaml != "")
        {
            ; Convertir a ruta absoluta si es relativa, porque WPF_Runner se ejecuta en _binDir
            if (SubStr(_srcXaml, 2, 1) != ":" && SubStr(_srcXaml, 1, 2) != "\\")
                _srcXaml := A_ScriptDir "\" _srcXaml

            if !FileExist(_srcXaml)
            {
                MsgBox, 16, Error, % "No se encontró el archivo XAML:`n" _srcXaml
                return false
            }
            FileRead, _fileContent, *P65001 %_srcXaml%
            if (ErrorLevel)
            {
                MsgBox, 16, Error, % "No se pudo leer:`n" _srcXaml
                return false
            }
            this.xaml := _fileContent
            _tmpXaml := _srcXaml
            _useFileArg := true
        }

        ; Quitar BOM UTF-8 si existe
        _bom := Chr(0xEF) . Chr(0xBB) . Chr(0xBF)
        if (SubStr(this.xaml,1,3) = _bom)
            this.xaml := SubStr(this.xaml,4)

        ; Quitar también la declaración XML si existe
        if InStr(this.xaml, "<?xml")
        {
            _xmlEnd := InStr(this.xaml, "?>")
            if (_xmlEnd > 0)
                this.xaml := SubStr(this.xaml, _xmlEnd + 2)
        }

        this.xaml := Trim(this.xaml," `t`r`n")

        if (this.iconPath)
        {
            _iconUri := "file:///" StrReplace(this.iconPath, "\", "/")
            this.xaml := RegExReplace(this.xaml, "i)(<Window(?=[\s>]))", "$1 Icon=""" _iconUri """ ", "", 1)
            _useFileArg := false
        }

        _binDir := A_ScriptDir "\Xaml_bin"
        if !FileExist(_binDir)
            FileCreateDir, % _binDir

        if (!_useFileArg)
        {
            _tmpXaml := _binDir "\AhkWpf_" this.id ".xaml"
            FileDelete, % _tmpXaml
            _h := FileOpen(_tmpXaml, "w", "UTF-8")
            if (!_h)
            {
                MsgBox, 16, Error, % "No se pudo crear archivo temporal XAML.`n" _tmpXaml
                return false
            }
            _h.Write(this.xaml)
            _h.Close()
        }

        FileCopy, % _tmpXaml, % _binDir "\DEBUG_XAML.xaml", 1

        ; Construir comando
        _exe  := this.exePath
        _id   := this.id
        _hwnd := this.receiverHwnd
        _assetsPath := _binDir "\Assets" ; Ya no se usa para copiar, se mantiene como arg

        cmd := """" _exe """ "
        cmd .= """FILE:" _tmpXaml """ "
        cmd .= """" _id """ "
        cmd .= """" _hwnd """ "
        cmd .= """" _assetsPath """"

        ; Log de debug
        FileDelete, % _binDir "\AhkRunCommand.log"
        FileAppend, % cmd, % _binDir "\AhkRunCommand.log"

        ; Ejecutar WPF
        Run, % cmd, % _binDir, , _pid
        this.pid := _pid
        FileAppend, % "XAMLGUI: Launched WPF pid=" _pid " cmd=" cmd "`n", % _binDir "\XAMLGUI_Debug.log"

        ; Esperar ventana
        Sleep, 1500

        WinGet, lista, List, ahk_pid %_pid%
        if (lista >= 1)
            this.wpfHwnd := WinExist("ahk_pid " _pid)
        FileAppend, % "XAMLGUI: WPF hwnd=" this.wpfHwnd " pid=" _pid " lista=" lista "`n", % A_Temp "\XAMLGUI_Debug.log"

        return true
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; UPDATE — actualizar cualquier propiedad de un control
    ; ─────────────────────────────────────────────────────────────────────

    Update(ctrlName, propName, value)
    {
        if !this.wpfHwnd
            return false

        packet := "Cmd=Update`n"
        packet .= "Ctrl=" ctrlName "`n"
        packet .= "Prop=" propName "`n"
        packet .= "Val=" this._B64Enc(value)

        return this._SendCopyData(this.wpfHwnd, packet)
    }

    ; Synchronous update: uses Dispatcher.Invoke so WPF processes it immediately
    ; before AHK continues. Use for flash effects and score updates.
    UpdateSync(ctrlName, propName, value)
    {
        if !this.wpfHwnd
            return false

        packet := "Cmd=SyncUpdate`n"
        packet .= "Ctrl=" ctrlName "`n"
        packet .= "Prop=" propName "`n"
        packet .= "Val=" this._B64Enc(value)

        return this._SendCopyData(this.wpfHwnd, packet)
    }

    ; Batch update: sends multiple updates in a single message
    ; updates is an array of objects: [{ctrl, prop, val}, ...]
    BatchUpdate(updates)
    {
        if !this.wpfHwnd
            return false
        data := ""
        for i, u in updates
            data .= u.ctrl "|" u.prop "|" u.val "`n"
        return this.Update("_Batch", "Cells", RTrim(data, "`n"))
    }

    ; Atajo: ui.AddRow("Lista", "1", "Juan", "555")
    AddRow(ctrlName, parts*)
    {
        row := ""
        for i, p in parts
            row .= (i = 1 ? "" : "|") . p
        return this.Update(ctrlName, "AddItem", row)
    }

    ; Atajo: ui.UpdateSelected("Lista", "1|Juan|555|mail@test.com")
    UpdateSelected(ctrlName, rowText)
    {
        return this.Update(ctrlName, "UpdateSelected", rowText)
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; SETCOLOR — cambiar color/estilo de un control individual
    ;
    ;   ctrlName : nombre del control (ej: "BtnEnviar")
    ;   prop     : Background | Foreground | BorderBrush | BorderThickness
    ;              FontSize | FontWeight | Opacity | Width | Height | ToolTip
    ;   value    : valor del color (#RRGGBB, nombre) o número
    ;
    ;   Ejemplo:
    ;     ui.SetColor("BtnEnviar", "Background", "#27AE60")
    ;     ui.SetColor("TxtNombre", "Foreground", "Red")
    ;     ui.SetColor("BtnLimpiar", "Opacity", "0.5")
    ; ─────────────────────────────────────────────────────────────────────

    SetColor(ctrlName, prop, value)
    {
        return this.Update(ctrlName, prop, value)
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; SETRESOURCE — actualizar un DynamicResource en Window.Resources
    ;
    ;   Todos los controles que usen {DynamicResource key} se actualizan
    ;   automáticamente sin necesidad de tocar cada control por separado.
    ;
    ;   Recursos estándar definidos en Demo.xaml:
    ;     Accent      → color de botones y elementos principales
    ;     AccentHover → color al pasar el mouse sobre botones
    ;     BgCard      → fondo de las tarjetas/secciones
    ;     Border      → color de bordes
    ;     TextPrimary → color de texto principal
    ;     TextSecond  → color de texto secundario/labels
    ;
    ;   Ejemplo:
    ;     ui.SetResource("Accent", "#E74C3C")
    ;     ui.SetResource("BgCard", "#2D2D2D")
    ;     ui.SetResource("TextPrimary", "#FFFFFF")
    ; ─────────────────────────────────────────────────────────────────────

    SetResource(resourceKey, colorValue)
    {
        return this.Update("_Resource", resourceKey, colorValue)
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; SETTHEME — aplicar un tema predefinido completo
    ;
    ;   Actualiza todos los DynamicResources y el fondo de la ventana
    ;   con una paleta prediseñada y armoniosa.
    ;
    ;   Temas disponibles:
    ;     Light  → blanco/azul (default)
    ;     Dark   → gris oscuro / azul claro
    ;     Blue   → azul Microsoft
    ;     Green  → verde esmeralda
    ;     Purple → violeta/lavanda
    ;     Red    → rojo/rosa
    ;     Orange → naranja/ámbar
    ;     Teal   → turquesa/menta
    ;
    ;   Ejemplo:
    ;     ui.SetTheme("Dark")
    ;     ui.SetTheme("Green")
    ; ─────────────────────────────────────────────────────────────────────

    SetTheme(themeName)
    {
        return this.Update("_Theme", "", themeName)
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; SETWINDOWPROP — modificar propiedades de la ventana principal
    ;
    ;   prop  : Background | Title | Opacity | Width | Height
    ;   value : valor correspondiente
    ;
    ;   Ejemplo:
    ;     ui.SetWindowProp("Title", "Mi App - Modo Oscuro")
    ;     ui.SetWindowProp("Background", "#1A1A2E")
    ;     ui.SetWindowProp("Opacity", "0.95")
    ; ─────────────────────────────────────────────────────────────────────

    SetWindowProp(prop, value)
    {
        if (prop = "Icon" && !this.wpfHwnd)
        {
            this.iconPath := value
            return true
        }
        return this.Update("_Window", prop, value)
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; CLOSE — cerrar la ventana WPF
    ; ─────────────────────────────────────────────────────────────────────

    Focus(ctrlName)
    {
        return this.Update(ctrlName, "Focus", "1")
    }

    Close()
    {
        if (this.pid)
            Process, Close, % this.pid
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; DISPATCH — procesar evento recibido desde WPF
    ; ─────────────────────────────────────────────────────────────────────

    _Dispatch(wParam, lParam)
    {
        pData  := NumGet(lParam + 0, 2 * A_PtrSize, "Ptr")
        packet := StrGet(pData, "UTF-16")

        state     := Object()
        ctrlName  := ""
        eventName := ""

        FileAppend, % "=== RECEIVE DISPATCH ===`nPacket:`n" packet "`n", % A_Temp "\AHK_Receiver.log"

        Loop, Parse, packet, `n, `r
        {
            line := A_LoopField
            if (line = "")
                continue

            eq := InStr(line, "=")
            if (!eq)
                continue

            k := SubStr(line,1,eq-1)
            v := this._B64Dec(SubStr(line,eq+1))

            if      (k = "InstanceId") ; ya fue validado antes
                continue
            else if (k = "EventCtrl")
                ctrlName := v
            else if (k = "EventName")
                eventName := v
            else
                state[k] := v
        }

        FileAppend, % "Decoded: Ctrl=" ctrlName ", Event=" eventName "`n", % A_Temp "\AHK_Receiver.log"

        if (ctrlName = "" || eventName = "")
        {
            FileAppend, % "Failed: Empty Ctrl or Event`n", % A_Temp "\AHK_Receiver.log"
            return 1
        }

        if !this.events.HasKey(ctrlName)
        {
            ; _Window events (Closed, StateChanged) bypass the registration check
            if (ctrlName != "_Window")
            {
                FileAppend, % "Failed: Control " ctrlName " not registered in events array.`nKeys:`n", % A_Temp "\AHK_Receiver.log"
                for key, val in this.events
                    FileAppend, % "- " key "`n", % A_Temp "\AHK_Receiver.log"
                return 1
            }
        }

        if (ctrlName != "_Window")
        {
            if !this.events[ctrlName].HasKey(eventName)
            {
                FileAppend, % "Failed: Event " eventName " not registered for " ctrlName ".`n", % A_Temp "\AHK_Receiver.log"
                return 1
            }

            cb := this.events[ctrlName][eventName]

            FileAppend, % "Success: Firing callback " cb "`n", % A_Temp "\AHK_Receiver.log"

            if IsFunc(cb)
                %cb%(state, ctrlName, eventName)
            else
                FileAppend, % "Failed: " cb " is not a valid function.`n", % A_Temp "\AHK_Receiver.log"
        }
        else if (this.events.HasKey("_Window") && this.events["_Window"].HasKey(eventName))
        {
            cb := this.events["_Window"][eventName]
            FileAppend, % "Success: Firing Window callback " cb "`n", % A_Temp "\AHK_Receiver.log"
            if IsFunc(cb)
                %cb%(state, ctrlName, eventName)
        }

        if (ctrlName = "_Window" && eventName = "Closed")
            ExitApp

        if (ctrlName = "_Window" && eventName = "StateChanged")
        {
            global ui
            if IsObject(ui)
            {
                if (state["State"] = "Maximized")
                    ui.Update("BtnMaximize", "Content", "❐")
                else
                    ui.Update("BtnMaximize", "Content", "□")
            }
            return 1
        }

        return 1
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; ENVÍO WM_COPYDATA
    ; ─────────────────────────────────────────────────────────────────────

    _SendCopyData(targetHwnd, str)
    {
        cbData := (StrLen(str)+1)*2
        VarSetCapacity(buf, cbData, 0)
        StrPut(str, &buf, "UTF-16")

        ; La estructura COPYDATASTRUCT mide 3 punteros (padding en x64)
        VarSetCapacity(cds, 3 * A_PtrSize, 0)
        NumPut(0,       cds, 0,             "Ptr")
        NumPut(cbData,  cds, A_PtrSize,     "UInt")
        NumPut(&buf,    cds, 2 * A_PtrSize, "Ptr")

        SendMessage, 0x004A, 0, &cds,, ahk_id %targetHwnd%
        return ErrorLevel
    }

    ; ─────────────────────────────────────────────────────────────────────
    ; BASE64
    ; ─────────────────────────────────────────────────────────────────────

    _B64Enc(str)
    {
        size := StrPut(str, "UTF-8")
        VarSetCapacity(bin, size)
        StrPut(str, &bin, "UTF-8")
        DllCall("crypt32\CryptBinaryToString", "Ptr", &bin, "UInt", size - 1, "UInt", 0x40000001, "Ptr", 0, "UIntP", b64Len)
        VarSetCapacity(b64, b64Len << (A_IsUnicode ? 1 : 0))
        DllCall("crypt32\CryptBinaryToString", "Ptr", &bin, "UInt", size - 1, "UInt", 0x40000001, "Str", b64, "UIntP", b64Len)
        
        ; Asegurar que no haya saltos de linea que rompan el parser en WPF_Runner
        StringReplace, b64, b64, `r,, All
        StringReplace, b64, b64, `n,, All
        return b64
    }

    _B64Dec(b64)
    {
        VarSetCapacity(src, StrLen(b64)+1, 0)
        StrPut(b64, &src, "CP0")

    DllCall("Crypt32\CryptStringToBinaryA"
            ,"Ptr",&src
            ,"UInt",0
            ,"UInt",6
            ,"Ptr",0
            ,"UInt*",outLen
            ,"Ptr",0
            ,"Ptr",0)

        VarSetCapacity(out, outLen+1, 0)

        if !DllCall("Crypt32\CryptStringToBinaryA"
            ,"Ptr",&src
            ,"UInt",0
            ,"UInt",6
            ,"Ptr",&out
            ,"UInt*",outLen
            ,"Ptr",0
            ,"Ptr",0)
            return ""

        str := StrGet(&out, outLen, "UTF-8")
        if (str = "")
            str := StrGet(&out, outLen, "CP0")

        return XAMLGUI_NormalizeDecoded(str)
    }
}

; ═══════════════════════════════════════════════════════════════════════════
; Handler global WM_COPYDATA
; ═══════════════════════════════════════════════════════════════════════════

XAMLGUI_OnWmCopyData(wParam, lParam)
{
    FileAppend, % "=== XAMLGUI_OnWmCopyData RECEIVED MESSAGE ===`n", % A_Temp "\AHK_Receiver.log"

    pData  := NumGet(lParam + 0, 2 * A_PtrSize, "Ptr")
    packet := StrGet(pData, "UTF-16")

    FileAppend, % "Packet:`n" packet "`n", % A_Temp "\AHK_Receiver.log"

    instanceId := ""

    Loop, Parse, packet, `n, `r
    {
        line := A_LoopField
        eq   := InStr(line, "=")
        if (!eq)
            continue

        k := SubStr(line,1,eq-1)
        v := SubStr(line,eq+1)

        if (k = "InstanceId")
        {
            outLen := 0
            VarSetCapacity(src, StrLen(v)+1, 0)
            StrPut(v, &src, "CP0")

            if DllCall("Crypt32\CryptStringToBinaryA"
                ,"Ptr",&src
                ,"UInt",0
                ,"UInt",6
                ,"Ptr",0
                ,"UInt*",outLen
                ,"Ptr",0
                ,"Ptr",0)
            {
                VarSetCapacity(out, outLen+1, 0)
                if DllCall("Crypt32\CryptStringToBinaryA"
                    ,"Ptr",&src
                    ,"UInt",0
                    ,"UInt",6
                    ,"Ptr",&out
                    ,"UInt*",outLen
                    ,"Ptr",0
                    ,"Ptr",0)
                {
                    instanceId := StrGet(&out, outLen, "UTF-8")
                    if (instanceId = "")
                        instanceId := StrGet(&out, outLen, "CP0")
                }
            }

            if (instanceId = "")
                instanceId := XAMLGUI_B64DecodeFallback(v)
            break
        }
    }

    if (instanceId = "")
    {
        FileAppend, % "Failed: instanceId is empty.`n", % A_Temp "\AHK_Receiver.log"
        return 0
    }

    if !XAMLGUI._instances.HasKey(instanceId)
    {
        len := StrLen(instanceId)
        FileAppend, % "Failed: " instanceId " not found in _instances. len=" len "`n", % A_Temp "\AHK_Receiver.log"
        FileAppend, % "Chars: ", % A_Temp "\AHK_Receiver.log"
        Loop, % len
        {
            c := SubStr(instanceId, A_Index, 1)
            FileAppend, % Asc(c) " ", % A_Temp "\AHK_Receiver.log"
        }
        FileAppend, "`n", % A_Temp "\AHK_Receiver.log"
        FileAppend, % "Keys available:`n", % A_Temp "\AHK_Receiver.log"
        for key, val in XAMLGUI._instances
            FileAppend, % "- " key "`n", % A_Temp "\AHK_Receiver.log"
        return 0
    }

    FileAppend, % "Instance match: " instanceId "`n", % A_Temp "\AHK_Receiver.log"
    return XAMLGUI._instances[instanceId]._Dispatch(wParam, lParam)
}

; ═══════════════════════════════════════════════════════════════════════════
; Utilidades globales
; ═══════════════════════════════════════════════════════════════════════════

XAMLGUI_Rand(mn, mx)
{
    Random, r, %mn%, %mx%
    return r
}

XAMLGUI_DecodeB64(b64)
{
    outLen := 0
    VarSetCapacity(src, StrLen(b64)+1, 0)
    StrPut(b64, &src, "CP0")

    if DllCall("Crypt32\CryptStringToBinaryA"
        ,"Ptr",&src
        ,"UInt",0
        ,"UInt",6
        ,"Ptr",0
        ,"UInt*",outLen
        ,"Ptr",0
        ,"Ptr",0)
    {
        VarSetCapacity(out, outLen+1, 0)
        if DllCall("Crypt32\CryptStringToBinaryA"
            ,"Ptr",&src
            ,"UInt",0
            ,"UInt",6
            ,"Ptr",&out
            ,"UInt*",outLen
            ,"Ptr",0
            ,"Ptr",0)
        {
            decoded := StrGet(&out, outLen, "UTF-8")
            if (decoded = "")
                decoded := StrGet(&out, outLen, "CP0")
            return decoded
        }
    }

    return XAMLGUI_B64DecodeFallback(b64)
}

XAMLGUI_B64DecodeFallback(b64)
{
    StringReplace, b64, b64, `r, , All
    StringReplace, b64, b64, `n, , All
    StringReplace, b64, b64, %A_Space%, , All
    StringReplace, b64, b64, `t, , All
    StringReplace, b64, b64, -, +, All
    StringReplace, b64, b64, _, /, All

    table := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    result := ""
    buffer := 0
    bits := 0

    Loop, Parse, b64
    {
        ch := A_LoopField
        if (ch = "=")
            break

        idx := InStr(table, ch) - 1
        if (idx < 0)
            continue

        buffer := (buffer << 6) | idx
        bits += 6

        while (bits >= 8)
        {
            bits -= 8
            result .= Chr((buffer >> bits) & 0xFF)
        }
    }

    return XAMLGUI_NormalizeDecoded(result)
}

XAMLGUI_NormalizeDecoded(str)
{
    normalized := ""
    Loop, Parse, str
    {
        c := A_LoopField
        code := Asc(c)
        if (code >= 32 && code != 127)
            normalized .= c
    }
    return Trim(normalized)
}
