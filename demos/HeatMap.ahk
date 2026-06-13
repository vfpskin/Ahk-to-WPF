#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

global ui       := new XAMLGUI(A_ScriptDir "\HeatMap.xaml")
global COLS     := 20
global ROWS     := 10
global CORES    := 6
global g_data   := []
global g_noise  := []
global g_playing := 0

; Buffers para lectura CPU (NtQuerySystemInformation)
global g_bufSize := CORES * 48
VarSetCapacity(g_buf1, g_bufSize, 0)
VarSetCapacity(g_buf2, g_bufSize, 0)

; Inicializar datos heatmap
Loop, % (COLS * ROWS)
{
    g_data[A_Index]  := 0
    g_noise[A_Index] := (A_Index * 37 + 13) / 97.0
}

; Eventos heatmap
ui.OnEvent("CloseBtn",  "Click", "OnClose")
ui.OnEvent("PlayBtn",   "Click", "OnPlayClick")
ui.OnEvent("RandomBtn", "Click", "OnRandom")
ui.OnEvent("ResetBtn",  "Click", "OnReset")

; Primera lectura CPU (base para el delta)
DllCall("ntdll.dll\NtQuerySystemInformation", "Int", 8, "Ptr", &g_buf1, "UInt", g_bufSize, "Ptr", 0)

; Timer CPU siempre activo (1 segundo)
SetTimer, UpdateCPU, 1000

PaintAllHeatmap()
PaintAllCPU(0)
ui.Show()
return

; ── Eventos heatmap ───────────────────────────────────────────────────────────

OnClose(state, ctrl, event)
{
    SetTimer, Animate,   Off
    SetTimer, UpdateCPU, Off
    ui.Close()
    ExitApp
}

OnPlayClick(state, ctrl, event)
{
    global g_playing
    if (g_playing = 0)
    {
        g_playing := 1
        SetTimer, Animate, 80
    }
    else
    {
        g_playing := 0
        SetTimer, Animate, Off
    }
}

OnRandom(state, ctrl, event)
{
    global g_data, COLS, ROWS
    Loop, % (COLS * ROWS)
    {
        seed := (A_Index * 1664525 + A_TickCount * 1013904223) & 0x7FFFFFFF
        g_data[A_Index] := Mod(seed, 101)
    }
    PaintAllHeatmap()
}

OnReset(state, ctrl, event)
{
    global g_data, COLS, ROWS, g_playing
    SetTimer, Animate, Off
    g_playing := 0
    Loop, % (COLS * ROWS)
        g_data[A_Index] := 0
    PaintAllHeatmap()
}

; ── Timer heatmap ─────────────────────────────────────────────────────────────

Animate:
    global g_data, g_noise, COLS, ROWS
    t += 0.08
    Loop, % (COLS * ROWS)
    {
        idx := A_Index
        col := Mod(idx - 1, COLS)
        row := (idx - 1) // COLS
        wave := Sin(t + col * 0.4 + g_noise[idx]) * 0.5
               + Sin(t * 0.7 + row * 0.5 + g_noise[idx] * 1.3) * 0.3
               + Sin(t * 1.3 + (col + row) * 0.3) * 0.2
        val := Round((wave + 1) / 2 * 100)
        val := (val < 0) ? 0 : (val > 100) ? 100 : val
        g_data[idx] := val
        UpdateHeatCell(col, row, val)
    }
return

; ── Timer CPU ────────────────────────────────────────────────────────────────

UpdateCPU:
    global g_buf1, g_buf2, g_bufSize, CORES

    ; Segunda lectura
    DllCall("ntdll.dll\NtQuerySystemInformation", "Int", 8, "Ptr", &g_buf2, "UInt", g_bufSize, "Ptr", 0)

    Loop, % CORES
    {
        i    := A_Index - 1
        base := i * 48

        idle1   := NumGet(g_buf1, base,      "Int64")
        kernel1 := NumGet(g_buf1, base + 8,  "Int64")
        user1   := NumGet(g_buf1, base + 16, "Int64")

        idle2   := NumGet(g_buf2, base,      "Int64")
        kernel2 := NumGet(g_buf2, base + 8,  "Int64")
        user2   := NumGet(g_buf2, base + 16, "Int64")

        dIdle   := idle2   - idle1
        dKernel := kernel2 - kernel1
        dUser   := user2   - user1
        dTotal  := dKernel + dUser
        dBusy   := dTotal  - dIdle
        usage   := (dTotal > 0) ? Round(dBusy / dTotal * 100) : 0
        usage   := (usage < 0) ? 0 : (usage > 100) ? 100 : usage

        UpdateCoreDisplay(i, usage)
    }

    ; Rotar buffers: buf2 pasa a ser base para la proxima lectura
    DllCall("RtlMoveMemory", "Ptr", &g_buf1, "Ptr", &g_buf2, "UInt", g_bufSize)
return

; ── Helpers heatmap ───────────────────────────────────────────────────────────

PaintAllHeatmap()
{
    global g_data, COLS, ROWS
    Loop, % ROWS
    {
        row := A_Index - 1
        Loop, % COLS
        {
            col := A_Index - 1
            UpdateHeatCell(col, row, g_data[row * COLS + col + 1])
        }
    }
}

UpdateHeatCell(col, row, value)
{
    global ui
    ui.Update("Cell_" . col . "_" . row, "Background", ValueToColor(value))
}

; ── Helpers CPU ───────────────────────────────────────────────────────────────

; Pinta las 3 columnas de un core segun su uso (llenado de abajo hacia arriba)
UpdateCoreDisplay(coreIdx, usage)
{
    global ui, ROWS
    ; Las 3 columnas del core empiezan en col = coreIdx * 3
    startCol := coreIdx * 3
    ; Cuantas filas iluminar (de abajo hacia arriba): usage% de 10 filas
    litRows := Round(usage / 100 * ROWS)

    Loop, 3
    {
        col := startCol + A_Index - 1
        Loop, % ROWS
        {
            row   := A_Index - 1
            ; fila 9 = abajo, fila 0 = arriba
            fromBottom := ROWS - 1 - row
            if (fromBottom < litRows)
                color := ValueToColor(usage)
            else
                color := "#FF111133"
            ui.Update("Cpu_" . col . "_" . row, "Background", color)
        }
    }

    ; Actualizar label de porcentaje
    ui.Update("CpuPct" . coreIdx, "Text", "Core " . coreIdx . ": " . usage . "%")
}

PaintAllCPU(usage)
{
    global CORES
    Loop, % CORES
        UpdateCoreDisplay(A_Index - 1, usage)
}

; ── Paleta de color comun ─────────────────────────────────────────────────────

ValueToColor(value)
{
    v := value / 100.0
    if (v < 0.25)
    {
        t := v / 0.25
        r := 0 , g := Round(t * 255) , b := 255
    }
    else if (v < 0.5)
    {
        t := (v - 0.25) / 0.25
        r := 0 , g := 255 , b := Round((1 - t) * 255)
    }
    else if (v < 0.75)
    {
        t := (v - 0.5) / 0.25
        r := Round(t * 255) , g := 255 , b := 0
    }
    else
    {
        t := (v - 0.75) / 0.25
        r := 255 , g := Round((1 - t) * 255) , b := 0
    }
    return "#FF" . RGBHex(r) . RGBHex(g) . RGBHex(b)
}

RGBHex(n)
{
    return Format("{:02X}", n)
}
