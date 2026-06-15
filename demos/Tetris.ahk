#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\Tetris.xaml")

; ── Board ──
global COLS := 10, ROWS := 20
global g_board := []

; ── Piece types ──
global I := 1, O := 2, T := 3, S := 4, Z := 5, J := 6, L := 7

; ── Colors per piece type ──
global g_colors := ["#FF00CED1", "#FFFFD700", "#FF9B59B6", "#FF2ECC71", "#FFE74C3C", "#FF3498DB", "#FFF39C12"]

; ── Piece definitions: [type][rotation][cell] = [row, col] ──
global g_pieces := []
g_pieces[I] := [[[1,0],[1,1],[1,2],[1,3]], [[0,2],[1,2],[2,2],[3,2]], [[2,0],[2,1],[2,2],[2,3]], [[0,1],[1,1],[2,1],[3,1]]]
g_pieces[O] := [[[0,0],[0,1],[1,0],[1,1]], [[0,0],[0,1],[1,0],[1,1]], [[0,0],[0,1],[1,0],[1,1]], [[0,0],[0,1],[1,0],[1,1]]]
g_pieces[T] := [[[0,1],[1,0],[1,1],[1,2]], [[0,1],[1,1],[1,2],[2,1]], [[1,0],[1,1],[1,2],[2,1]], [[0,1],[1,0],[1,1],[2,1]]]
g_pieces[S] := [[[0,1],[0,2],[1,0],[1,1]], [[0,1],[1,1],[1,2],[2,2]], [[1,1],[1,2],[2,0],[2,1]], [[0,0],[1,0],[1,1],[2,1]]]
g_pieces[Z] := [[[0,0],[0,1],[1,1],[1,2]], [[0,2],[1,1],[1,2],[2,1]], [[1,0],[1,1],[2,1],[2,2]], [[0,1],[1,0],[1,1],[2,0]]]
g_pieces[J] := [[[0,0],[1,0],[1,1],[1,2]], [[0,1],[0,2],[1,1],[2,1]], [[1,0],[1,1],[1,2],[2,2]], [[0,1],[1,1],[2,0],[2,1]]]
g_pieces[L] := [[[0,2],[1,0],[1,1],[1,2]], [[0,1],[1,1],[2,1],[2,2]], [[1,0],[1,1],[1,2],[2,0]], [[0,0],[0,1],[1,1],[2,1]]]

; ── Game state ──
global g_curType := 0, g_curRot := 0, g_curRow := 0, g_curCol := 0
global g_nextType := 0
global g_score := 0, g_level := 1, g_lines := 0
global g_gameOver := false, g_paused := false
global g_renderCells := [], g_renderGhostCells := []

; ── Events ──
ui.OnEvent("CloseBtn", "Click", "OnClose")
ui.OnEvent("NewGameBtn", "Click", "OnNewGame")
ui.OnEvent("PauseBtn", "Click", "OnPause")
ui.OnEvent("_Window", "KeyLeft", "OnKeyLeft")
ui.OnEvent("_Window", "KeyRight", "OnKeyRight")
ui.OnEvent("_Window", "KeyDown", "OnKeyDown")
ui.OnEvent("_Window", "KeyUp", "OnKeyRotate")
ui.OnEvent("_Window", "KeySpace", "OnKeyDrop")
ui.OnEvent("_Window", "KeyP", "OnKeyPause")
ui.OnEvent("_Window", "KeyR", "OnKeyRestart")

; ── Start ──
InitBoard()
g_nextType := RandomPiece()
ui.Show()
NewGame()
return

; ── Board init ──
InitBoard()
{
    global g_board, COLS, ROWS
    g_board := []
    Loop, % ROWS
    {
        row := []
        Loop, % COLS
            row[A_Index] := 0
        g_board[A_Index] := row
    }
}

; ── New game ──
NewGame()
{
    global g_score, g_level, g_lines, g_gameOver, g_paused, g_curType, g_curRot, g_curRow, g_curCol, g_nextType
    g_score := 0
    g_level := 1
    g_lines := 0
    g_gameOver := false
    g_paused := false
    InitBoard()
    g_nextType := RandomPiece()
    SpawnPiece()
    SetTimer, GameTick, % GetTickRate()
    ui.Update("GameOverText", "Visibility", "Collapsed")
    ui.Update("PauseBtn", "Content", "PAUSE")
    RenderAll()
    UpdateInfo()
}

; ── Piece helpers ──
RandomPiece()
{
    global I, O, T, S, Z, J, L
    Random, r, 1, 7
    return r
}

SpawnPiece()
{
    global g_curType, g_curRot, g_curRow, g_curCol, g_nextType
    g_curType := g_nextType
    g_curRot := 0
    g_curRow := 0
    g_curCol := 3
    g_nextType := RandomPiece()
    if Collides(g_curType, g_curRot, g_curRow, g_curCol)
    {
        g_gameOver := true
        SetTimer, GameTick, Off
        ui.Update("GameOverText", "Visibility", "Visible")
    }
}

GetCells(type, rot)
{
    global g_pieces
    return g_pieces[type][rot + 1]
}

Collides(type, rot, row, col)
{
    global g_board, COLS, ROWS
    cells := GetCells(type, rot)
    for i, offset in cells
    {
        r := row + offset[1]
        c := col + offset[2]
        ; Allow cells above visible area (r < 0) during spawn
        if (r < 0)
            continue
        if (r >= ROWS || c < 0 || c >= COLS)
            return true
        if (g_board[r+1][c+1] != 0)
            return true
    }
    return false
}

; ── Movement ──
MovePiece(dc, dr)
{
    global g_curType, g_curRot, g_curRow, g_curCol, g_gameOver, g_paused
    if g_gameOver || g_paused
        return
    nr := g_curRow + dr
    nc := g_curCol + dc
    if !Collides(g_curType, g_curRot, nr, nc)
    {
        g_curRow := nr
        g_curCol := nc
        RenderScene()
    }
}

RotatePiece()
{
    global g_curType, g_curRot, g_curRow, g_curCol, g_gameOver, g_paused
    if g_gameOver || g_paused
        return
    nr := (g_curRot + 1) & 3
    if !Collides(g_curType, nr, g_curRow, g_curCol)
    {
        g_curRot := nr
        RenderScene()
    }
}

HardDrop()
{
    global g_curType, g_curRot, g_curRow, g_curCol, g_gameOver, g_paused
    if g_gameOver || g_paused
        return
    Loop
    {
        if Collides(g_curType, g_curRot, g_curRow + 1, g_curCol)
            break
        g_curRow++
    }
    LockPiece()
}

; ── Gravity ──
GameTick:
    if g_gameOver || g_paused
        return
    if Collides(g_curType, g_curRot, g_curRow + 1, g_curCol)
    {
        LockPiece()
        return
    }
    g_curRow++
    RenderScene()
return

; ── Lock & line clear ──
LockPiece()
{
    global g_curType, g_curRot, g_curRow, g_curCol, g_board
    cells := GetCells(g_curType, g_curRot)
    for i, offset in cells
    {
        r := g_curRow + offset[1]
        c := g_curCol + offset[2]
        if (r >= 0 && r < ROWS && c >= 0 && c < COLS)
            g_board[r+1][c+1] := g_curType
    }
    ClearLines()
    SpawnPiece()
    RenderAll()
    UpdateInfo()
}

ClearLines()
{
    global g_board, ROWS, COLS, g_lines, g_score, g_level
    cleared := 0
    r := ROWS
    while (r >= 1)
    {
        full := true
        Loop, % COLS
        {
            if (g_board[r][A_Index] = 0)
            {
                full := false
                break
            }
        }
        if full
        {
            ; Flash effect: briefly show white line (sync to ensure it renders before Sleep)
            SetTimer, GameTick, Off
            Loop, % COLS
                ui.UpdateSync("Cell_" . (A_Index-1) . "_" . (r-1), "Background", "#FFFFFFFF")
            Sleep, 60
            ; Remove row
            Loop, % COLS
                g_board[r][A_Index] := 0
            SetTimer, GameTick, % GetTickRate()
            ; Shift rows down
            rr := r
            while (rr > 1)
            {
                Loop, % COLS
                    g_board[rr][A_Index] := g_board[rr-1][A_Index]
                rr--
            }
            Loop, % COLS
                g_board[1][A_Index] := 0
            cleared++
            ; Stay on same row index (rows shifted down)
        }
        else
            r--
    }

    if (cleared > 0)
    {
        g_lines += cleared
        ; Scoring: 1=100, 2=300, 3=500, 4=800 (× level)
        pts := [100, 300, 500, 800]
        g_score += pts[cleared] * g_level
        ; Level up every 10 lines
        newLevel := (g_lines // 10) + 1
        if (newLevel > g_level)
        {
            g_level := newLevel
            SetTimer, GameTick, % GetTickRate()
        }
        UpdateInfo()
    }
}

GetTickRate()
{
    global g_level
    ; Level 1=1000ms, 10=100ms, scales down
    rate := 1000 - (g_level - 1) * 80
    if (rate < 80)
        rate := 80
    return rate
}

; ── Render (batch-optimized) ──
RenderScene()
{
    global g_renderCells, g_renderGhostCells, g_board, ROWS, COLS, g_colors
    global g_curType, g_curRot, g_curRow, g_curCol
    updates := []
    ; Clear old piece cells (restore from board)
    for i, cell in g_renderCells
    {
        r := cell[1], c := cell[2]
        if (r >= 0 && r < ROWS && c >= 0 && c < COLS)
        {
            val := g_board[r+1][c+1]
            updates.Push({ctrl: "Cell_" . c . "_" . r, prop: "Background", val: (val = 0) ? "#FF111133" : g_colors[val]})
        }
    }
    ; Clear old ghost cells (restore from board)
    for i, cell in g_renderGhostCells
    {
        r := cell[1], c := cell[2]
        if (r >= 0 && r < ROWS && c >= 0 && c < COLS)
        {
            val := g_board[r+1][c+1]
            updates.Push({ctrl: "Cell_" . c . "_" . r, prop: "Background", val: (val = 0) ? "#FF111133" : g_colors[val]})
        }
    }
    g_renderCells := []
    g_renderGhostCells := []
    ; Draw new piece
    if (g_curType != 0)
    {
        cells := GetCells(g_curType, g_curRot)
        color := g_colors[g_curType]
        for i, offset in cells
        {
            r := g_curRow + offset[1], c := g_curCol + offset[2]
            if (r >= 0 && r < ROWS && c >= 0 && c < COLS)
            {
                updates.Push({ctrl: "Cell_" . c . "_" . r, prop: "Background", val: color})
                g_renderCells.Push([r, c])
            }
        }
    }
    ; Draw new ghost
    if (g_curType != 0)
    {
        ghostRow := g_curRow
        Loop
        {
            if Collides(g_curType, g_curRot, ghostRow + 1, g_curCol)
                break
            ghostRow++
        }
        if (ghostRow != g_curRow)
        {
            cells := GetCells(g_curType, g_curRot)
            ghostColor := "#FF334455"
            for i, offset in cells
            {
                r := ghostRow + offset[1], c := g_curCol + offset[2]
                if (r >= 0 && r < ROWS && c >= 0 && c < COLS)
                {
                    if (g_board[r+1][c+1] = 0)
                    {
                        isCurrent := false
                        curCells := GetCells(g_curType, g_curRot)
                        for j, co in curCells
                        {
                            if (g_curRow + co[1] = r && g_curCol + co[2] = c)
                            {
                                isCurrent := true
                                break
                            }
                        }
                        if !isCurrent
                        {
                            updates.Push({ctrl: "Cell_" . c . "_" . r, prop: "Background", val: ghostColor})
                            g_renderGhostCells.Push([r, c])
                        }
                    }
                }
            }
        }
    }
    ui.BatchUpdate(updates)
}

RenderAll()
{
    global g_board, g_curType, g_curRot, g_curRow, g_curCol, ROWS, COLS, g_renderCells, g_renderGhostCells
    global g_colors, g_nextType
    g_renderCells := []
    g_renderGhostCells := []
    updates := []
    ; Draw board
    Loop, % ROWS
    {
        r := A_Index, row := r - 1
        Loop, % COLS
        {
            c := A_Index, col := c - 1
            val := g_board[r][c]
            updates.Push({ctrl: "Cell_" . col . "_" . row, prop: "Background", val: (val = 0) ? "#FF111133" : g_colors[val]})
        }
    }
    ; Draw current piece
    if (g_curType != 0)
    {
        cells := GetCells(g_curType, g_curRot)
        color := g_colors[g_curType]
        for i, offset in cells
        {
            r := g_curRow + offset[1], c := g_curCol + offset[2]
            if (r >= 0 && r < ROWS && c >= 0 && c < COLS)
            {
                updates.Push({ctrl: "Cell_" . c . "_" . r, prop: "Background", val: color})
                g_renderCells.Push([r, c])
            }
        }
    }
    ; Draw ghost
    if (g_curType != 0)
    {
        ghostRow := g_curRow
        Loop
        {
            if Collides(g_curType, g_curRot, ghostRow + 1, g_curCol)
                break
            ghostRow++
        }
        if (ghostRow != g_curRow)
        {
            cells := GetCells(g_curType, g_curRot)
            ghostColor := "#FF334455"
            for i, offset in cells
            {
                r := ghostRow + offset[1], c := g_curCol + offset[2]
                if (r >= 0 && r < ROWS && c >= 0 && c < COLS)
                {
                    if (g_board[r+1][c+1] = 0)
                    {
                        isCurrent := false
                        curCells := GetCells(g_curType, g_curRot)
                        for j, co in curCells
                        {
                            if (g_curRow + co[1] = r && g_curCol + co[2] = c)
                            {
                                isCurrent := true
                                break
                            }
                        }
                        if !isCurrent
                        {
                            updates.Push({ctrl: "Cell_" . c . "_" . r, prop: "Background", val: ghostColor})
                            g_renderGhostCells.Push([r, c])
                        }
                    }
                }
            }
        }
    }
    ; Draw next piece
    Loop, 4
    {
        row := A_Index - 1
        Loop, 4
        {
            col := A_Index - 1
            updates.Push({ctrl: "Next_" . col . "_" . row, prop: "Background", val: "#FF111133"})
        }
    }
    if (g_nextType != 0)
    {
        cells := GetCells(g_nextType, 0)
        color := g_colors[g_nextType]
        for i, offset in cells
        {
            r := offset[1], c := offset[2]
            if (r >= 0 && r < 4 && c >= 0 && c < 4)
                updates.Push({ctrl: "Next_" . c . "_" . r, prop: "Background", val: color})
        }
    }
    ui.BatchUpdate(updates)
}

UpdateInfo()
{
    global ui, g_score, g_level, g_lines
    ui.UpdateSync("ScoreText", "Text", g_score)
    ui.UpdateSync("LevelText", "Text", g_level)
    ui.UpdateSync("LinesText", "Text", g_lines)
}

; ── Event handlers ──
OnClose(state, ctrl, event)
{
    SetTimer, GameTick, Off
    ui.Close()
    ExitApp
}

OnNewGame(state, ctrl, event)
{
    NewGame()
}

OnPause(state, ctrl, event)
{
    global g_paused, g_gameOver
    if g_gameOver
        return
    g_paused := !g_paused
    ui.Update("PauseBtn", "Content", g_paused ? "RESUME" : "PAUSE")
    if !g_paused
        RenderAll()
}

OnKeyLeft(state, ctrl, event)
{
    MovePiece(-1, 0)
}
OnKeyRight(state, ctrl, event)
{
    MovePiece(1, 0)
}
OnKeyDown(state, ctrl, event)
{
    MovePiece(0, 1)
}
OnKeyRotate(state, ctrl, event)
{
    RotatePiece()
}
OnKeyDrop(state, ctrl, event)
{
    HardDrop()
}

OnKeyPause(state, ctrl, event)
{
    global g_paused, g_gameOver
    if g_gameOver
        return
    g_paused := !g_paused
    ui.Update("PauseBtn", "Content", g_paused ? "RESUME" : "PAUSE")
}

OnKeyRestart(state, ctrl, event)
{
    NewGame()
}

; ── Direct keyboard controls (bypass WPF→AHK roundtrip for faster response) ──
#IfWinActive, Tetris
Left::MovePiece(-1, 0)
Right::MovePiece(1, 0)
Down::MovePiece(0, 1)
Up::RotatePiece()
Space::HardDrop()
p::Hotkey_Pause()
r::NewGame()
#IfWinActive

Hotkey_Pause()
{
    global g_paused, g_gameOver
    if g_gameOver
        return
    g_paused := !g_paused
    ui.UpdateSync("PauseBtn", "Content", g_paused ? "RESUME" : "PAUSE")
    if !g_paused
        RenderAll()
}
