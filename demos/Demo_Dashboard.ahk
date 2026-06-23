#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

#Include %A_ScriptDir%\..\XAMLGUI.ahk

global ui := new XAMLGUI(A_ScriptDir . "\Demo_Dashboard.xaml")

; ==================================================================
; DEFAULTS
; =================================================================+
global d := { M1: { val: "377", arr: "▼", pct: "37%", cmp: "Comparison period: 601" }
            , M2: { val: "64.276", arr: "▲", pct: "2%", cmp: "Comparison period: 62.737" }
            , M3: { val: "6037", arr: "▲", pct: "2%", cmp: "Comparison period: 5935" }
            , D1: { t: "307", c: 34.95
                  , s1: "8.7 26.3", s2: "5.2 29.8", s3: "4.2 30.8", s4: "16.8 18.2"
                  , p1: "8.1%", p2: "6.5%", p3: "5.5%", p4: "5.2%", o: "Other (+60%)" }
            , D2: { t: "306k", c: 36.91
                  , s1: "4.5 32.4", s2: "3.7 33.2", s3: "2.7 34.2", s4: "1.9 35.0", s5: "1.8 35.1", s6: "22.3 14.6"
                  , p1: "12.1%", p2: "9.9%", p3: "7.4%", p4: "5.2%", p5: "4.9%", p6: "60.5%" } }

global dr := [ { o: "13", c: "47" }, { o: "10", c: "28" }
             , { o: "20", c: "23" }, { o: "15", c: "21" }, { o: "5", c: "20" } ]

global as := { M1: "▼", M2: "▲", M3: "▲" }

Rand(m, x) {
    Random, r, %m%, %x%
    return r
}
Tog(a) {
    if (a = "▲")
        return "▼"
    return "▲"
}
Aclr(a) {
    if (a = "▲")
        return "#3FC972"
    return "#F25F5F"
}

UpdV(p, v, pct, c) {
    ui.Update(p . "_Val", "Text", v)
    ui.Update(p . "_Pct", "Text", pct)
    ui.Update(p . "_Cmp", "Text", c)
}
UpdA(p) {
    a := as[p]
    ui.Update(p . "_Arrow", "Text", a)
    c := Aclr(a)
    ui.Update(p . "_Arrow", "Foreground", c)
    ui.Update(p . "_Pct", "Foreground", c)
}

; ==================================================================
; CARD 1 — NEW CONVERSATIONS
; ==================================================================
ui.OnEvent("BtnR1", "Click", "OnR1")
ui.OnEvent("BtnT1", "Click", "OnT1")
ui.OnEvent("BtnD1", "Click", "OnD1")

OnR1(s, x, y) {
    UpdV("M1", Rand(200, 900), Rand(1, 99) . "%", "Comparison period: " . Rand(100, 800))
}
OnT1(s, x, y) {
    as.M1 := Tog(as.M1)
    UpdA("M1")
}
OnD1(s, x, y) {
    as.M1 := d.M1.arr
    UpdV("M1", d.M1.val, d.M1.pct, d.M1.cmp)
    UpdA("M1")
}

; ==================================================================
; CARD 2 — CONVERSATIONS
; ==================================================================
ui.OnEvent("BtnR2", "Click", "OnR2")
ui.OnEvent("BtnT2", "Click", "OnT2")
ui.OnEvent("BtnD2", "Click", "OnD2")

OnR2(s, x, y) {
    UpdV("M2", Rand(10000, 150000), Rand(1, 99) . "%", "Comparison period: " . Rand(10000, 150000))
}
OnT2(s, x, y) {
    as.M2 := Tog(as.M2)
    UpdA("M2")
}
OnD2(s, x, y) {
    as.M2 := d.M2.arr
    UpdV("M2", d.M2.val, d.M2.pct, d.M2.cmp)
    UpdA("M2")
}

; ==================================================================
; CARD 3 — LEADS
; ==================================================================
ui.OnEvent("BtnR3", "Click", "OnR3")
ui.OnEvent("BtnT3", "Click", "OnT3")
ui.OnEvent("BtnD3", "Click", "OnD3")

OnR3(s, x, y) {
    UpdV("M3", Rand(1000, 20000), Rand(1, 99) . "%", "Comparison period: " . Rand(1000, 20000))
}
OnT3(s, x, y) {
    as.M3 := Tog(as.M3)
    UpdA("M3")
}
OnD3(s, x, y) {
    as.M3 := d.M3.arr
    UpdV("M3", d.M3.val, d.M3.pct, d.M3.cmp)
    UpdA("M3")
}

; ==================================================================
; CARD 4 — LEADERBOARD
; ==================================================================
ui.OnEvent("BtnR4", "Click", "OnR4")
ui.OnEvent("BtnT4", "Click", "OnT4")
ui.OnEvent("BtnD4", "Click", "OnD4")

OnR4(s, x, y) {
    Loop, 5 {
        ui.Update("R" . A_Index . "_Opn", "Text", Rand(1, 50))
        ui.Update("R" . A_Index . "_Cls", "Text", Rand(1, 80))
    }
}
OnT4(s, x, y) {
    Loop, 5 {
        ui.Update("R" . A_Index . "_Opn", "Text", Rand(1, 50))
        ui.Update("R" . A_Index . "_Cls", "Text", Rand(1, 80))
    }
}
OnD4(s, x, y) {
    Loop, 5 {
        ui.Update("R" . A_Index . "_Opn", "Text", dr[A_Index].o)
        ui.Update("R" . A_Index . "_Cls", "Text", dr[A_Index].c)
    }
}

; ==================================================================
; CARD 5 — OPEN CONVERSATIONS BY TEAMMATE (Donut 1)
; ==================================================================
ui.OnEvent("BtnR5", "Click", "OnR5")
ui.OnEvent("BtnT5", "Click", "OnT5")
ui.OnEvent("BtnD5", "Click", "OnD5")

OnR5(s, x, y) {
    t := Rand(200, 500)
    s1 := Rand(15, 35)
    s2 := Rand(10, 25)
    s3 := Rand(5, 20)
    s4 := 100 - s1 - s2 - s3
    if (s4 < 10) {
        s4 := 10
        s1 := 100 - s2 - s3 - s4
    }
    c := d.D1.c
    d1 := Round(c * s1 / 100, 1)
    d2 := Round(c * s2 / 100, 1)
    d3 := Round(c * s3 / 100, 1)
    d4 := Round(c * s4 / 100, 1)
    ui.Update("D1_S1", "StrokeDashArray", d1 . " " . Round(c - d1, 1))
    ui.Update("D1_S2", "StrokeDashArray", d2 . " " . Round(c - d2, 1))
    ui.Update("D1_S3", "StrokeDashArray", d3 . " " . Round(c - d3, 1))
    ui.Update("D1_S4", "StrokeDashArray", d4 . " " . Round(c - d4, 1))
    ui.Update("D1_Total", "Text", t)
    r := 100 - s1 - s2 - s3 - s4
    ui.Update("D1_P1", "Text", s1 . "%")
    ui.Update("D1_P2", "Text", s2 . "%")
    ui.Update("D1_P3", "Text", s3 . "%")
    ui.Update("D1_P4", "Text", s4 . "%")
    ui.Update("D1_Other", "Text", "Other (+" . r . "%)")
}
OnT5(s, x, y) {
    ui.Update("D1_S1", "StrokeDashArray", d.D1.s4)
    ui.Update("D1_S4", "StrokeDashArray", d.D1.s1)
    ui.Update("D1_P1", "Text", "48%")
    ui.Update("D1_P4", "Text", "25%")
}
OnD5(s, x, y) {
    ui.Update("D1_S1", "StrokeDashArray", d.D1.s1)
    ui.Update("D1_S2", "StrokeDashArray", d.D1.s2)
    ui.Update("D1_S3", "StrokeDashArray", d.D1.s3)
    ui.Update("D1_S4", "StrokeDashArray", d.D1.s4)
    ui.Update("D1_Total", "Text", d.D1.t)
    ui.Update("D1_P1", "Text", d.D1.p1)
    ui.Update("D1_P2", "Text", d.D1.p2)
    ui.Update("D1_P3", "Text", d.D1.p3)
    ui.Update("D1_P4", "Text", d.D1.p4)
    ui.Update("D1_Other", "Text", d.D1.o)
}

; ==================================================================
; CARD 6 — USERS BY TAG NAME (Donut 2)
; ==================================================================
ui.OnEvent("BtnR6", "Click", "OnR6")
ui.OnEvent("BtnT6", "Click", "OnT6")
ui.OnEvent("BtnD6", "Click", "OnD6")

OnR6(s, x, y) {
    t := Rand(200, 500) . "k"
    p1 := Rand(5, 15)
    p2 := Rand(5, 12)
    p3 := Rand(3, 10)
    p4 := Rand(2, 8)
    p5 := Rand(2, 6)
    p6 := 100 - p1 - p2 - p3 - p4 - p5
    if (p6 < 20) {
        p6 := 20
        p1 := 100 - p2 - p3 - p4 - p5 - p6
    }
    c := d.D2.c
    d1 := Round(c * p1 / 100, 1)
    d2 := Round(c * p2 / 100, 1)
    d3 := Round(c * p3 / 100, 1)
    d4 := Round(c * p4 / 100, 1)
    d5 := Round(c * p5 / 100, 1)
    d6 := Round(c * p6 / 100, 1)
    ui.Update("D2_S1", "StrokeDashArray", d1 . " " . Round(c - d1, 1))
    ui.Update("D2_S2", "StrokeDashArray", d2 . " " . Round(c - d2, 1))
    ui.Update("D2_S3", "StrokeDashArray", d3 . " " . Round(c - d3, 1))
    ui.Update("D2_S4", "StrokeDashArray", d4 . " " . Round(c - d4, 1))
    ui.Update("D2_S5", "StrokeDashArray", d5 . " " . Round(c - d5, 1))
    ui.Update("D2_S6", "StrokeDashArray", d6 . " " . Round(c - d6, 1))
    a2 := Round(p1 * 3.6, 1)
    a3 := Round((p1 + p2) * 3.6, 1)
    a4 := Round((p1 + p2 + p3) * 3.6, 1)
    a5 := Round((p1 + p2 + p3 + p4) * 3.6, 1)
    a6 := Round((p1 + p2 + p3 + p4 + p5) * 3.6, 1)
    ui.Update("D2_S2", "RenderTransform", "rotate(" . a2 . ")")
    ui.Update("D2_S3", "RenderTransform", "rotate(" . a3 . ")")
    ui.Update("D2_S4", "RenderTransform", "rotate(" . a4 . ")")
    ui.Update("D2_S5", "RenderTransform", "rotate(" . a5 . ")")
    ui.Update("D2_S6", "RenderTransform", "rotate(" . a6 . ")")
    ui.Update("D2_Total", "Text", t)
    ui.Update("D2_P1", "Text", p1 . "%")
    ui.Update("D2_P2", "Text", p2 . "%")
    ui.Update("D2_P3", "Text", p3 . "%")
    ui.Update("D2_P4", "Text", p4 . "%")
    ui.Update("D2_P5", "Text", p5 . "%")
    ui.Update("D2_P6", "Text", p6 . "%")
}
OnT6(s, x, y) {
    ui.Update("D2_S1", "StrokeDashArray", d.D2.s3)
    ui.Update("D2_S3", "StrokeDashArray", d.D2.s1)
    ui.Update("D2_S2", "StrokeDashArray", d.D2.s4)
    ui.Update("D2_S4", "StrokeDashArray", d.D2.s2)
    ui.Update("D2_S1", "RenderTransform", "rotate(79.2)")
    ui.Update("D2_S3", "RenderTransform", "rotate(0)")
    ui.Update("D2_S2", "RenderTransform", "rotate(105.8)")
    ui.Update("D2_S4", "RenderTransform", "rotate(43.6)")
    ui.Update("D2_P1", "Text", "7.4%")
    ui.Update("D2_P2", "Text", "5.2%")
    ui.Update("D2_P3", "Text", "12.1%")
    ui.Update("D2_P4", "Text", "9.9%")
}
OnD6(s, x, y) {
    ui.Update("D2_S1", "StrokeDashArray", d.D2.s1)
    ui.Update("D2_S2", "StrokeDashArray", d.D2.s2)
    ui.Update("D2_S3", "StrokeDashArray", d.D2.s3)
    ui.Update("D2_S4", "StrokeDashArray", d.D2.s4)
    ui.Update("D2_S5", "StrokeDashArray", d.D2.s5)
    ui.Update("D2_S6", "StrokeDashArray", d.D2.s6)
    ui.Update("D2_S2", "RenderTransform", "rotate(43.6)")
    ui.Update("D2_S3", "RenderTransform", "rotate(79.2)")
    ui.Update("D2_S4", "RenderTransform", "rotate(105.8)")
    ui.Update("D2_S5", "RenderTransform", "rotate(124.6)")
    ui.Update("D2_S6", "RenderTransform", "rotate(142.2)")
    ui.Update("D2_Total", "Text", d.D2.t)
    ui.Update("D2_P1", "Text", d.D2.p1)
    ui.Update("D2_P2", "Text", d.D2.p2)
    ui.Update("D2_P3", "Text", d.D2.p3)
    ui.Update("D2_P4", "Text", d.D2.p4)
    ui.Update("D2_P5", "Text", d.D2.p5)
    ui.Update("D2_P6", "Text", d.D2.p6)
}

; ==================================================================
; SHOW
; ==================================================================
if !ui.Show() {
    MsgBox, No se pudo cargar el Dashboard.
    ExitApp
}

~Esc::ExitApp
