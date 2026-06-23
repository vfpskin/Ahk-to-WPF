#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\ChartDemo2.xaml")

ui.OnEvent("BtnLoadAll",   "Click", "OnLoadAll")
ui.OnEvent("BtnRandCol",   "Click", "OnRandCol")
ui.OnEvent("BtnRandLine",  "Click", "OnRandLine")
ui.OnEvent("BtnRandPie",   "Click", "OnRandPie")
ui.OnEvent("BtnRandBar",   "Click", "OnRandBar")
ui.OnEvent("BtnRandArea",  "Click", "OnRandArea")
ui.OnEvent("BtnRandScatter","Click", "OnRandScatter")
ui.OnEvent("BtnClose",     "Click", "OnClose")

; Load all charts at startup
OnLoadAll("", "", "")

ui.Show()
return

; ---------------------------------------------------------------
; Load All - static demo data
; ---------------------------------------------------------------
OnLoadAll(state, ctrl, event)
{
    global ui
    ui.Update("LblStatus", "Text", "Loading all charts with demo data...")

    ui.Update("ChartCol", "ChartType", "Column")
    ui.Update("ChartCol", "Title", "Monthly Sales")
    ui.Update("ChartCol", "Data", "Sales|Jan|120|Feb|200|Mar|150|Apr|80|May|250|Jun|180|Jul|210|Aug|195|Sep|170|Oct|140|Nov|110|Dec|230")

    ui.Update("ChartLine", "ChartType", "Line")
    ui.Update("ChartLine", "Title", "Temperature C")
    ui.Update("ChartLine", "Data", "Temp|Jan|5|Feb|7|Mar|12|Apr|18|May|22|Jun|27|Jul|30|Aug|29|Sep|24|Oct|17|Nov|10|Dec|6")

    ui.Update("ChartPie", "ChartType", "Pie")
    ui.Update("ChartPie", "Title", "Market Share")
    ui.Update("ChartPie", "Data", "Share|Prod A|35|Prod B|25|Prod C|20|Prod D|12|Other|8")

    ui.Update("ChartBar", "ChartType", "Bar")
    ui.Update("ChartBar", "Title", "Population (M)")
    ui.Update("ChartBar", "Data", "Pop|China|1412|India|1408|USA|335|Indonesia|277|Pakistan|241|Nigeria|224|Brazil|216")

    ui.Update("ChartArea", "ChartType", "Area")
    ui.Update("ChartArea", "Title", "Growth %")
    ui.Update("ChartArea", "Data", "Q1|2019|2.3|2020|-3.4|2021|5.7|2022|2.9|2023|3.2|2024|2.8")
    ui.Update("ChartArea", "AddSeries", "Q2|2019|2.1|2020|-2.8|2021|5.2|2022|3.1|2023|2.5|2024|3.0")

    ui.Update("ChartScatter", "ChartType", "Scatter")
    ui.Update("ChartScatter", "Title", "Price vs Qty")
    ui.Update("ChartScatter", "Data", "Data|10|25|20|40|30|55|40|38|50|70|60|62|70|80|80|45|90|90|100|72")

    ui.Update("LblStatus", "Text", "6 charts loaded - Click Random on any card to test live data update from AHK")
}

; ---------------------------------------------------------------
; Random data generators for each chart
; ---------------------------------------------------------------
OnRandCol(state, ctrl, event)
{
    global ui
    data := RandomData("Values", 8)
    ui.Update("ChartCol", "Data", data)
    ui.Update("ChartCol", "Title", "Random Column")
    ui.Update("LblStatus", "Text", "Column chart updated with random data")
}

OnRandLine(state, ctrl, event)
{
    global ui
    data := RandomData("Values", 8)
    ui.Update("ChartLine", "Data", data)
    ui.Update("ChartLine", "Title", "Random Line")
    ui.Update("LblStatus", "Text", "Line chart updated with random data")
}

OnRandPie(state, ctrl, event)
{
    global ui
    data := RandomData("Segments", 6)
    ui.Update("ChartPie", "Data", data)
    ui.Update("ChartPie", "Title", "Random Pie")
    ui.Update("LblStatus", "Text", "Pie chart updated with random data")
}

OnRandBar(state, ctrl, event)
{
    global ui
    data := RandomData("Values", 7)
    ui.Update("ChartBar", "Data", data)
    ui.Update("ChartBar", "Title", "Random Bar")
    ui.Update("LblStatus", "Text", "Bar chart updated with random data")
}

OnRandArea(state, ctrl, event)
{
    global ui
    data := RandomData("Values", 8)
    ui.Update("ChartArea", "Data", data)
    ; Add a second series for Area
    Sleep 100
    data2 := RandomData("Series 2", 8)
    ui.Update("ChartArea", "AddSeries", data2)
    ui.Update("ChartArea", "Title", "Random Area")
    ui.Update("LblStatus", "Text", "Area chart updated with random data (2 series)")
}

OnRandScatter(state, ctrl, event)
{
    global ui
    data := RandomScatterData("Points", 10)
    ui.Update("ChartScatter", "Data", data)
    ui.Update("ChartScatter", "Title", "Random Scatter")
    ui.Update("LblStatus", "Text", "Scatter chart updated with random data")
}

; ---------------------------------------------------------------
; Helper: generate random data string
; Format: "Label|Cat1|Val1|Cat2|Val2|..."
; ---------------------------------------------------------------
RandomData(label, count)
{
    cats := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    result := label
    Loop % count
    {
        idx := Mod(A_Index - 1, 10) + 1
        cat := cats[idx]
        val := RandInt(5, 100)
        result .= "|" . cat . "|" . val
    }
    return result
}

; ---------------------------------------------------------------
; Helper: generate random scatter data (numeric X values)
; ---------------------------------------------------------------
RandomScatterData(label, count)
{
    result := label
    Loop % count
    {
        x := RandInt(5, 100)
        y := RandInt(5, 100)
        result .= "|" . x . "|" . y
    }
    return result
}

; ---------------------------------------------------------------
; Helper: random integer
; ---------------------------------------------------------------
RandInt(min, max)
{
    Random r, min, max
    return r
}

; ---------------------------------------------------------------
; Close
; ---------------------------------------------------------------
OnClose(state, ctrl, event)
{
    ui.Close()
    ExitApp
}
