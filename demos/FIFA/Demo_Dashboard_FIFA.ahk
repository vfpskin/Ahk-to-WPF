#Requires AutoHotkey 1.1
#SingleInstance Force

#Include %A_ScriptDir%\..\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\..\TitleBar.ahk
#Include %A_ScriptDir%\Class_SQLiteDB.ahk
#Include %A_ScriptDir%\FIFA_DB.ahk

global ui
global gCurrentSection := "Home"
global gThemeOrder := ["Oscuro", "Claro", "FIFA", "Azul", "Verde", "Profesional", "Moderno"]
global gThemeIndex := 1
global gThemeMap := {}

InitThemeCatalog()
DB_Conectar()
DB_CrearTablas()

xamlPath := A_ScriptDir "\Dashboard_FIFA.xaml"
if (!FileExist(xamlPath)) {
    MsgBox, 16, Error, % "No se encontró Dashboard_FIFA.xaml en:`n" xamlPath
    ExitApp
}

FileRead, xamlContent, *P65001 %xamlPath%
if (ErrorLevel || xamlContent = "") {
    MsgBox, 16, Error, No se pudo leer Dashboard_FIFA.xaml
    ExitApp
}

ui := new XAMLGUI(xamlContent, A_ScriptDir "\..\..\WPF_Runner.exe")

ui.OnEvent("NavHome", "Click", "OnNavigate")
ui.OnEvent("NavCountries", "Click", "OnNavigate")
ui.OnEvent("NavGroups", "Click", "OnNavigate")
ui.OnEvent("NavFixture", "Click", "OnNavigate")
ui.OnEvent("NavStats", "Click", "OnNavigate")
ui.OnEvent("NavStadiums", "Click", "OnNavigate")
ui.OnEvent("BtnTheme", "Click", "OnToggleTheme")
ui.OnEvent("BtnRefresh", "Click", "OnRefresh")
ui.OnEvent("BtnGetTicketsHome", "Click", "OnHomeAction")
ui.OnEvent("BtnFullScheduleHome", "Click", "OnHomeAction")
ui.OnEvent("BtnSearchCountries", "Click", "OnSearchCountries")
ui.OnEvent("TxtSearchCountry", "Enter", "OnSearchCountries")
ui.OnEvent("TxtSearchConfed", "Enter", "OnSearchCountries")
ui.OnEvent("BtnResetCountries", "Click", "OnResetCountries")
ui.OnEvent("TxtFifa2026Title", "Click", "OnTextBlockClick")
ui.OnEvent("_Window", "Closed", "OnWpfClosed")

; Initialize title bar (BtnTheme is handled separately in sidebar, not in title bar)
InitTitleBar(ui, {title: "FIFA 2026 Dashboard", showTheme: false, onClose: "TitleBar_OnClose"})

ui.SetWindowProp("Icon", A_ScriptDir "\L_icon.ico")

ui.Show()

savedTheme := DB_GetConfig("LastTheme", "Oscuro")
if (GetThemeIndex(savedTheme) = 0)
    savedTheme := "Oscuro"
SetThemeByLabel(savedTheme, false)

ui.SetWindowProp("Title", "Dashboard FIFA | Demo AHK + WPF")
MostrarVista("Home")
RefrescarDashboard()
SetTimer, ActualizarCuentaRegresiva, 1000

return

OnNavigate(state, ctrl, event)
{
    if (ctrl = "NavHome")
        MostrarVista("Home")
    else if (ctrl = "NavCountries")
        MostrarVista("Paises")
    else if (ctrl = "NavGroups")
        MostrarVista("Grupos")
    else if (ctrl = "NavFixture")
        MostrarVista("Fixture")
    else if (ctrl = "NavStats")
        MostrarVista("Estadisticas")
    else if (ctrl = "NavStadiums")
        MostrarVista("Estadios")
}

OnToggleTheme(state, ctrl, event)
{
    global gThemeIndex, gThemeOrder

    gThemeIndex := Mod(gThemeIndex, gThemeOrder.MaxIndex()) + 1
    tema := gThemeOrder[gThemeIndex]
    SetThemeByLabel(tema, true)
}

OnRefresh(state, ctrl, event)
{
    RefrescarDashboard()
    MostrarVista(gCurrentSection)
}

OnHomeAction(state, ctrl, event)
{
    global ui
    MostrarVista("Fixture")
    ui.Update("TxtLastUpdate", "Text", "Home action: " ctrl)
}

OnSearchCountries(state, ctrl, event)
{
    global ui
    pais := Trim(state["TxtSearchCountry"])
    conf := Trim(state["TxtSearchConfed"])
    CargarPaises(pais, conf)

    mensaje := "Filtro aplicado"
    if (pais != "")
        mensaje .= " país='" pais "'"
    if (conf != "")
        mensaje .= " conf='" conf "'"
    if (pais = "" && conf = "")
        mensaje := "Mostrando todos los países desde SQLite."

    ui.Update("TxtCountriesStatus", "Text", mensaje)
}

OnResetCountries(state, ctrl, event)
{
    ui.Update("TxtSearchCountry", "Text", "")
    ui.Update("TxtSearchConfed", "Text", "")
    CargarPaises()
    ui.Update("TxtCountriesStatus", "Text", "Mostrando selección completa de SQLite.")
}

OnWpfClosed(state, ctrl, event)
{
    return
}

OnTextBlockClick(state, ctrl, event)
{
    MsgBox, 64, TextBlock Click, ¡Hiciste click en el TextBlock!`n`nControl: %ctrl%`nEvento: %event%
}

MostrarVista(nombreVista)
{
    global ui, gCurrentSection
    gCurrentSection := nombreVista

    vistas := ["PageHome", "PagePaises", "PageGrupos", "PageFixture", "PageEstadisticas", "PageEstadios"]
    for index, vista in vistas
    {
        visible := (vista = "Page" nombreVista) ? "Visible" : "Collapsed"
        ui.Update(vista, "Visibility", visible)
    }

    botones := {Home:"NavHome", Paises:"NavCountries", Grupos:"NavGroups", Fixture:"NavFixture", Estadisticas:"NavStats", Estadios:"NavStadiums"}
    titulo := {Home:"Inicio", Paises:"Países participantes", Grupos:"Grupos", Fixture:"Fixture", Estadisticas:"Estadísticas", Estadios:"Estadios"}
    subtitulo := {Home:"Resumen visual del torneo y widgets principales"
                , Paises:"Búsqueda, confederación y datos de selección"
                , Grupos:"Tabla base de posiciones por grupo"
                , Fixture:"Calendario de partidos, sedes y horarios"
                , Estadisticas:"Indicadores generales y rankings del torneo"
                , Estadios:"Sedes, capacidad y ubicación"}

    if (botones.HasKey(nombreVista))
        ResaltarMenu(botones[nombreVista])

    if (titulo.HasKey(nombreVista)) {
        ui.Update("TxtSectionTitle", "Text", titulo[nombreVista])
        ui.Update("TxtSectionDesc", "Text", subtitulo[nombreVista])
    }
}

ResaltarMenu(botonActivo)
{
    global ui
    botones := ["NavHome", "NavCountries", "NavGroups", "NavFixture", "NavStats", "NavStadiums"]
    for index, boton in botones
    {
        if (boton = botonActivo) {
            ui.SetColor(boton, "Background", "#1D4ED8")
            ui.SetColor(boton, "Foreground", "#FFFFFF")
        } else {
            ui.SetColor(boton, "Background", "")
            ui.SetColor(boton, "Foreground", "#E5E7EB")
        }
    }
}

RefrescarDashboard()
{
    global ui

    CargarPaises()
    CargarFixture()
    CargarEstadios()

    ui.Update("TxtTeamsValue", "Text", DB_ContarFilas("Paises"))
    ui.Update("TxtStadiumsValue", "Text", DB_ContarFilas("Estadios"))
    ui.Update("TxtMatchesValue", "Text", DB_ContarFilas("Partidos"))
    ui.Update("TxtGoalsValue", "Text", DB_TotalGoles())
    ui.Update("TxtNextMatch", "Text", DB_ProximoPartido())
    ui.Update("TxtNextMatchMeta", "Text", DB_ProximoPartidoMeta())
    ui.Update("TxtLastResult", "Text", DB_UltimoResultado())

    FormatTime, ahora,, dd/MM/yyyy HH:mm:ss
    ui.Update("TxtLastUpdate", "Text", "Actualizado " ahora)
}

ActualizarCuentaRegresiva:
    global ui
    objetivo := "20260611000000"
    FormatTime, ahora,, yyyyMMddHHmmss
    diff := objetivo
    EnvSub, diff, %ahora%, Seconds
    if (diff < 0) {
        texto := "Torneo iniciado"
    } else {
        dias := Floor(diff / 86400)
        horas := Floor(Mod(diff, 86400) / 3600)
        minutos := Floor(Mod(diff, 3600) / 60)
        segundos := Mod(diff, 60)
        texto := dias "d " horas "h " minutos "m " segundos "s"
    }
    ui.Update("TxtCountdown", "Text", texto)
return

SetThemeByLabel(label, saveToDb := true)
{
    global ui, gThemeMap, gThemeIndex

    if (!gThemeMap.HasKey(label))
        label := "Oscuro"

    gThemeIndex := GetThemeIndex(label)
    if (gThemeIndex = 0)
        gThemeIndex := 1

    tema := gThemeMap[label]
    ui.SetTheme(tema.base)

    if (tema.HasKey("Accent"))
        ui.SetResource("Accent", tema.Accent)
    if (tema.HasKey("AccentHover"))
        ui.SetResource("AccentHover", tema.AccentHover)
    if (tema.HasKey("BgCard"))
        ui.SetResource("BgCard", tema.BgCard)
    if (tema.HasKey("Border"))
        ui.SetResource("Border", tema.Border)
    if (tema.HasKey("TextPrimary"))
        ui.SetResource("TextPrimary", tema.TextPrimary)
    if (tema.HasKey("TextSecondary"))
        ui.SetResource("TextSecondary", tema.TextSecondary)
    if (tema.HasKey("TextMuted"))
        ui.SetResource("TextMuted", tema.TextMuted)
    if (tema.HasKey("WindowBg"))
        ui.SetResource("WindowBg", tema.WindowBg)
    if (tema.HasKey("SidebarBg"))
        ui.SetResource("SidebarBg", tema.SidebarBg)
    if (tema.HasKey("Surface"))
        ui.SetResource("Surface", tema.Surface)
    if (tema.HasKey("Surface2"))
        ui.SetResource("Surface2", tema.Surface2)
    if (tema.HasKey("Accent2"))
        ui.SetResource("Accent2", tema.Accent2)

    if (tema.HasKey("WindowBg"))
        ui.SetWindowProp("Background", tema.WindowBg)

    ui.Update("TxtLastUpdate", "Text", "Tema aplicado: " label)
    DB_SetConfig("LastTheme", label)
}

GetThemeIndex(label)
{
    global gThemeOrder
    for index, item in gThemeOrder
        if (item = label)
            return index
    return 0
}

InitThemeCatalog()
{
    global gThemeMap

    gThemeMap["Oscuro"] := {base:"Dark", Accent:"#5B9BD5", AccentHover:"#4A87C0", BgCard:"#2D2D2D", Border:"#404040", TextPrimary:"#F0F0F0", TextSecondary:"#AAAAAA", TextMuted:"#64748B", WindowBg:"#1E1E1E", SidebarBg:"#0F172A", Surface:"#111827", Surface2:"#172033", Accent2:"#14B8A6"}
    gThemeMap["Claro"] := {base:"Light", Accent:"#2E6DA4", AccentHover:"#245A8A", BgCard:"#FFFFFF", Border:"#DCDCDC", TextPrimary:"#1A1A1A", TextSecondary:"#666666", TextMuted:"#64748B", WindowBg:"#F4F4F4", SidebarBg:"#FFFFFF", Surface:"#FFFFFF", Surface2:"#F3F4F6", Accent2:"#2563EB"}
    gThemeMap["FIFA"] := {base:"Dark", Accent:"#00C853", AccentHover:"#00A844", BgCard:"#101827", Border:"#1F2937", TextPrimary:"#F8FAFC", TextSecondary:"#CBD5E1", TextMuted:"#94A3B8", WindowBg:"#08111F", SidebarBg:"#07111C", Surface:"#0F172A", Surface2:"#111827", Accent2:"#00B8D9"}
    gThemeMap["Azul"] := {base:"Blue", Accent:"#0078D4", AccentHover:"#005A9E", BgCard:"#EBF5FB", Border:"#AED6F1", TextPrimary:"#0D1117", TextSecondary:"#2471A3", TextMuted:"#5B6B7A", WindowBg:"#D6EAF8", SidebarBg:"#DCEFFC", Surface:"#F7FBFF", Surface2:"#EAF3FF", Accent2:"#1D4ED8"}
    gThemeMap["Verde"] := {base:"Green", Accent:"#27AE60", AccentHover:"#1E8449", BgCard:"#EAFAF1", Border:"#A9DFBF", TextPrimary:"#0D1117", TextSecondary:"#1E8449", TextMuted:"#5F7C6A", WindowBg:"#D5F5E3", SidebarBg:"#EAFBF1", Surface:"#F4FFF8", Surface2:"#E1F9EB", Accent2:"#10B981"}
    gThemeMap["Profesional"] := {base:"Dark", Accent:"#4F8CFF", AccentHover:"#3B73D1", BgCard:"#121826", Border:"#273244", TextPrimary:"#E5E7EB", TextSecondary:"#A7B0BE", TextMuted:"#6B7280", WindowBg:"#0B1220", SidebarBg:"#0F172A", Surface:"#111827", Surface2:"#172033", Accent2:"#22C55E"}
    gThemeMap["Moderno"] := {base:"Teal", Accent:"#14B8A6", AccentHover:"#0F766E", BgCard:"#E8F8F5", Border:"#A2D9CE", TextPrimary:"#0D1117", TextSecondary:"#0F766E", TextMuted:"#4B5563", WindowBg:"#D1F2EB", SidebarBg:"#E6FFFB", Surface:"#F4FFFD", Surface2:"#DDF7F3", Accent2:"#06B6D4"}
}

CargarPaises(nombreFiltro := "", confFiltro := "")
{
    global ui
    tabla := DB_ObtenerPaises(nombreFiltro, confFiltro)
    ui.Update("LvCountries", "ClearItems", "")
    if (!IsObject(tabla))
        return

    Loop, % tabla.RowCount
    {
        fila := tabla.Rows[A_Index]
        texto := fila[2] "|" fila[4] "|" fila[5] "|" fila[6] "|" fila[7] "|" fila[8] "|" fila[9]
        ui.Update("LvCountries", "AddItem", texto)
    }
}

CargarFixture()
{
    global ui
    tabla := DB_ObtenerPartidos()
    ui.Update("LvFixture", "ClearItems", "")
    if (!IsObject(tabla))
        return

    Loop, % tabla.RowCount
    {
        fila := tabla.Rows[A_Index]
        texto := fila[2] "|" fila[3] "|" fila[11] "|" fila[12] "|" fila[4] "|" fila[5] "|" fila[9] "|" fila[10]
        ui.Update("LvFixture", "AddItem", texto)
    }
}

CargarEstadios()
{
    global ui
    tabla := DB_ObtenerEstadios()
    ui.Update("LvStadiums", "ClearItems", "")
    if (!IsObject(tabla))
        return

    Loop, % tabla.RowCount
    {
        fila := tabla.Rows[A_Index]
        texto := fila[2] "|" fila[3] "|" fila[4] "|" fila[5] "|" fila[6] "|" fila[8] "|" fila[9]
        ui.Update("LvStadiums", "AddItem", texto)
    }
}

DB_TotalGoles()
{
    tabla := ""
    if !DB_Conectar()
        return 0
    if !gFifaDB.GetTable("SELECT IFNULL(SUM(goles_local + goles_visitante), 0) AS total FROM Partidos", tabla, 1)
        return 0
    if (tabla.RowCount < 1)
        return 0
    return tabla.Rows[1][1]
}

DB_ProximoPartido()
{
    tabla := ""
    if !DB_Conectar()
        return ""
    if !gFifaDB.GetTable("SELECT equipo_local, equipo_visitante FROM Partidos ORDER BY fecha ASC, hora ASC LIMIT 1", tabla, 1)
        return ""
    if (tabla.RowCount < 1)
        return ""
    return tabla.Rows[1][1] " vs " tabla.Rows[1][2]
}

DB_ProximoPartidoMeta()
{
    tabla := ""
    if !DB_Conectar()
        return ""
    if !gFifaDB.GetTable("SELECT fecha, hora, fase, grupo, estadio_id FROM Partidos ORDER BY fecha ASC, hora ASC LIMIT 1", tabla, 1)
        return ""
    if (tabla.RowCount < 1)
        return ""
    return tabla.Rows[1][3] " · Grupo " tabla.Rows[1][4] " · " DB_NombreEstadioPorId(tabla.Rows[1][5]) " · " tabla.Rows[1][2]
}

DB_UltimoResultado()
{
    tabla := ""
    if !DB_Conectar()
        return ""
    if !gFifaDB.GetTable("SELECT equipo_local, goles_local, goles_visitante, equipo_visitante FROM Partidos ORDER BY id DESC LIMIT 1", tabla, 1)
        return ""
    if (tabla.RowCount < 1)
        return ""
    return tabla.Rows[1][1] " " tabla.Rows[1][2] " - " tabla.Rows[1][3] " " tabla.Rows[1][4]
}
