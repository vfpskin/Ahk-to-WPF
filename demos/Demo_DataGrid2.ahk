#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

#Include %A_ScriptDir%\..\XAMLGUI.ahk

global ui := new XAMLGUI(A_ScriptDir . "\Demo_DataGrid2.xaml")

global Records := []
global NextID := 1
global FilterText := ""
global ColorMode := "none"
global ColVis := {ID:1, Name:1, Email:1, Department:1, Salary:1, City:1, Status:1}
global ColKeys := ["ID","Name","Email","Department","Salary","City","Status"]
global ColBtns := ["BtnColID","BtnColName","BtnColEmail","BtnColDept","BtnColSalary","BtnColCity","BtnColStatus"]

global FirstNames := ["Liam","Emma","Noah","Olivia","James","Ava","Oliver","Isabella","Elijah","Sophia"
                     ,"Mateo","Mia","Lucas","Amelia","Levi","Harper","Ethan","Evelyn","Daniel","Abigail"
                     ,"Benjamin","Emily","Henry","Elizabeth","Alexander","Sofia","William","Avery","Sebastian","Ella"]
global LastNames := ["Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez"
                    ,"Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor","Moore","Jackson","Martin"
                    ,"Lee","White","Harris","Clark","Lewis","Robinson","Walker","Young","Allen","King"]
global Departments := ["Engineering","Marketing","Sales","Human Resources","Finance","Operations"
                      ,"Design","Support","Legal","Product Management","Research","QA"]
global Cities := ["New York","Los Angeles","Chicago","Houston","Phoenix","Philadelphia","San Antonio"
                 ,"San Diego","Dallas","San Jose","Austin","Jacksonville","Fort Worth","Columbus","Charlotte"
                 ,"Indianapolis","Seattle","Denver","Washington","Miami"]
global Statuses := ["Active","Active","Active","Active","Active","Inactive","Pending","Suspended","Disabled","Archived"]

ui.OnEvent("Btn100", "Click", "On100")
ui.OnEvent("Btn200", "Click", "On200")
ui.OnEvent("Btn500", "Click", "On500")
ui.OnEvent("Btn1000", "Click", "On1000")
ui.OnEvent("BtnBatch500", "Click", "OnBatch500")
ui.OnEvent("BtnClear", "Click", "OnClear")
ui.OnEvent("BtnDelSel", "Click", "OnDelSel")
ui.OnEvent("BtnDelRnd", "Click", "OnDelRnd")
ui.OnEvent("BtnColorRnd", "Click", "OnColorRnd")
ui.OnEvent("BtnColorVal", "Click", "OnColorVal")
ui.OnEvent("BtnColorCol", "Click", "OnColorCol")
ui.OnEvent("BtnClearCol", "Click", "OnClearCol")
ui.OnEvent("TxtFilter", "Enter", "OnFilter")
ui.OnEvent("BtnFilter", "Click", "OnFilter")
ui.OnEvent("BtnClearFilter", "Click", "OnClearFilter")
ui.OnEvent("GridData", "SelectionChanged", "OnSelChg")

Loop, 7 {
    ui.OnEvent(ColBtns[A_Index], "Click", "OnToggleCol")
}

Rand(m, x) {
    Random, r, %m%, %x%
    return r
}

GenerateRec(id) {
    fn := FirstNames[Rand(1, FirstNames.Length())]
    ln := LastNames[Rand(1, LastNames.Length())]
    dept := Departments[Rand(1, Departments.Length())]
    city := Cities[Rand(1, Cities.Length())]
    stat := Statuses[Rand(1, Statuses.Length())]
    sal := Rand(30000, 180000)
    email := fn . "." . ln . "@example.com"
    rec := {}
    rec.ID := id
    rec.Name := fn . " " . ln
    rec.Email := email
    rec.Department := dept
    rec.Salary := sal
    rec.City := city
    rec.Status := stat
    return rec
}

LoadRecords(n) {
    global Records, NextID
    Loop % n {
        Records.Push(GenerateRec(NextID))
        NextID++
    }
}

RecToStr(r) {
    return r.ID . "|" . r.Name . "|" . r.Email . "|" . r.Department . "|" . r.Salary . "|" . r.City . "|" . r.Status
}

GetColors(r) {
    global ColorMode
    if (ColorMode = "random")
        return RandColor(7)
    if (ColorMode = "value")
        return ValueColors(r)
    if (ColorMode = "columns")
        return ColumnColors()
    return "|||||||"
}

RandColor(cnt) {
    s := ""
    Loop % cnt {
        Random, r, 0, 255
        Random, g, 0, 255
        Random, b, 0, 255
        hex := Format("#{:02X}{:02X}{:02X}", r, g, b)
        if (A_Index > 1)
            s .= "|"
        s .= hex
    }
    return s
}

ValueColors(r) {
    s := ""
    colors := ["", "", "", "", "", "", ""]
    if (r.Salary > 120000)
        colors[5] := "#1A4A2A"
    else if (r.Salary < 40000)
        colors[5] := "#4A1A1A"
    if (r.Status = "Active")
        colors[7] := "#1A3A1A"
    else if (r.Status = "Inactive")
        colors[7] := "#3A3A1A"
    else if (r.Status = "Suspended" || r.Status = "Disabled")
        colors[7] := "#4A1A1A"
    Loop 7 {
        if (A_Index > 1)
            s .= "|"
        s .= colors[A_Index]
    }
    return s
}

ColumnColors() {
    return "#1A2A4A|#1A3A2A|#2A1A3A|#3A2A1A|#1A4A2A|#2A2A4A|#1A3A3A"
}

RenderGrid() {
    global Records, FilterText, ColorMode, ui
    ShowProc()
    data := Records
    if (FilterText != "") {
        f := FilterText
        data := []
        Loop % Records.Length() {
            r := Records[A_Index]
            if (InStr(r.ID, f) || InStr(r.Name, f) || InStr(r.Email, f)
                || InStr(r.Department, f) || InStr(r.Salary, f)
                || InStr(r.City, f) || InStr(r.Status, f))
                data.Push(r)
        }
    }
    ui.Update("GridData", "Clear", "")
    Loop % data.Length() {
        r := data[A_Index]
        ui.Update("GridData", "AddItem", RecToStr(r))
        if (ColorMode != "none")
            ui.Update("GridData", "AddColorItem", GetColors(r))
    }
    if (ColorMode != "none")
        ui.Update("GridData", "RefreshGrid", "")
    HideProc()
}

BatchRender() {
    global Records, FilterText, ColorMode, ui
    ShowProc()
    data := Records
    if (FilterText != "") {
        f := FilterText
        data := []
        Loop % Records.Length() {
            r := Records[A_Index]
            if (InStr(r.ID, f) || InStr(r.Name, f) || InStr(r.Email, f)
                || InStr(r.Department, f) || InStr(r.Salary, f)
                || InStr(r.City, f) || InStr(r.Status, f))
                data.Push(r)
        }
    }
    batch := ""
    Loop % data.Length() {
        r := data[A_Index]
        batch .= "GridData|AddItem|" . RecToStr(r) . "`n"
        if (ColorMode != "none")
            batch .= "GridData|AddColorItem|" . GetColors(r) . "`n"
    }
    if (ColorMode != "none")
        batch .= "GridData|RefreshGrid|`n"
    if (batch != "")
        ui.Update("_Batch", "Cells", batch)
    HideProc()
}

UpdateStatus() {
    global Records, FilterText, ui
    ui.Update("LblRecords", "Text", "Records: " . Records.Length())
    ui.Update("LblSelected", "Text", "Selected: -")
    if (FilterText != "")
        ui.Update("LblStatus", "Text", "Filtered: " . FilterText)
    else
        ui.Update("LblStatus", "Text", "Ready")
    ui.Update("LblStatus", "Foreground", "#3FC972")
}

ShowProc(msg := "Processing...") {
    global ui
    ui.Update("LblStatus", "Text", msg)
    ui.Update("LblStatus", "Foreground", "#F8BB86")
}

HideProc() {
    global ui
    UpdateStatus()
}

OnSelChg(state, ctrl, event) {
    global ui
    idx := state["GridData_SelectedIndex"]
    if (idx = "" || idx < 0)
        ui.Update("LblSelected", "Text", "Selected: -")
    else
        ui.Update("LblSelected", "Text", "Selected: row " . idx)
}

On100(s, x, y) {
    ShowProc()
    LoadRecords(100)
    RenderGrid()
}

On200(s, x, y) {
    ShowProc()
    LoadRecords(200)
    RenderGrid()
}

On500(s, x, y) {
    ShowProc()
    LoadRecords(500)
    RenderGrid()
}

On1000(s, x, y) {
    ShowProc()
    LoadRecords(1000)
    RenderGrid()
}

OnBatch500(s, x, y) {
    ShowProc()
    LoadRecords(500)
    BatchRender()
}

OnClear(s, x, y) {
    global Records, NextID, FilterText, ColorMode
    Records := []
    NextID := 1
    FilterText := ""
    ColorMode := "none"
    ui.Update("GridData", "Clear", "")
    UpdateStatus()
    ui.Update("LblSelected", "Text", "Selected: -")
}

OnDelSel(s, x, y) {
    global Records, FilterText, ui
    idx := s["GridData_SelectedIndex"]
    if (idx = "" || idx < 0)
        return
    if (idx >= Records.Length() && FilterText = "")
        return
    if (FilterText != "") {
        f := FilterText
        filtered := []
        Loop % Records.Length() {
            r := Records[A_Index]
            if (InStr(r.ID, f) || InStr(r.Name, f) || InStr(r.Email, f)
                || InStr(r.Department, f) || InStr(r.Salary, f)
                || InStr(r.City, f) || InStr(r.Status, f))
                filtered.Push(r)
        }
        if (idx < filtered.Length()) {
            targetID := filtered[idx + 1].ID
            Loop % Records.Length() {
                if (Records[A_Index].ID = targetID) {
                    Records.RemoveAt(A_Index)
                    break
                }
            }
        }
    } else {
        Records.RemoveAt(idx + 1)
    }
    RenderGrid()
}

OnDelRnd(s, x, y) {
    global Records
    if (Records.Length() = 0)
        return
    r := Rand(1, Records.Length())
    Records.RemoveAt(r)
    RenderGrid()
}

OnColorRnd(s, x, y) {
    global ColorMode
    ColorMode := "random"
    RenderGrid()
}

OnColorVal(s, x, y) {
    global ColorMode
    ColorMode := "value"
    RenderGrid()
}

OnColorCol(s, x, y) {
    global ColorMode
    ColorMode := "columns"
    RenderGrid()
}

OnClearCol(s, x, y) {
    global ColorMode
    ColorMode := "none"
    RenderGrid()
}

OnFilter(s, x, y) {
    global FilterText
    FilterText := s["TxtFilter"]
    RenderGrid()
}

OnClearFilter(s, x, y) {
    global FilterText, ui
    FilterText := ""
    ui.Update("TxtFilter", "Text", "")
    RenderGrid()
}

OnToggleCol(s, x, y) {
    global ColVis, ColKeys, ColBtns, ui
    idx := 0
    Loop 7 {
        if (ColBtns[A_Index] = x) {
            idx := A_Index
            break
        }
    }
    if (idx = 0)
        return
    key := ColKeys[idx]
    ColVis[key] := !ColVis[key]
    n := ColVis[key] ? "1" : "0"
    ui.Update("GridData", "SetColVisibility", key . "|" . n)
    ui.Update(x, "Opacity", ColVis[key] ? "1" : "0.4")
}

if !ui.Show() {
    MsgBox, Failed to load DataGrid Demo.
    ExitApp
}
