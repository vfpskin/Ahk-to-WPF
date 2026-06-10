; ======================================================================
; ThemeManager.ahk -- Centralized Theme Management
;
; Usage:
;   1. Include files:
;      #Include %A_ScriptDir%\..\themes.ahk
;      #Include %A_ScriptDir%\..\ThemeManager.ahk
;
;   2. Initialize at startup:
;      InitThemeManager(ui [, themeSubset])
;      - themeSubset: optional array of theme names to cycle through
;        (defaults to all themes from ThemeOrder)
;
;   3. Register theme button:
;      ui.OnEvent("BtnTheme", "Click", "CycleTheme")
;
;   4. Apply a theme immediately:
;      ApplyTheme("Navy")
;
;   5. Get current state:
;      GetThemeIndex()    ; returns 1-based index
;      GetCurrentTheme()  ; returns current theme name string
;
;   6. Save/restore theme preference:
;      FileDelete, %config%
;      FileAppend, % GetCurrentTheme(), %config%
;      FileRead, t, %config%
;      ApplyTheme(Trim(t))
;
; To add themes: edit themes.ahk only
; ======================================================================

; ======================================================================
; GLOBAL STATE
; ======================================================================
global _ThemeMgr := ""

; ======================================================================
; PUBLIC API
; ======================================================================

; Initializes the ThemeManager with a UI instance.
; ui         - XAMLGUI instance
; subset     - optional array of theme names (defaults to ThemeOrder)
InitThemeManager(ui, subset := "") {
    global _ThemeMgr
    global ThemeOrder
    if !IsObject(subset)
        subset := ThemeOrder
    _ThemeMgr := new _ThemeManagerCore(ui, subset)
}

; Applies a theme by name. Falls back to first available theme if not found.
ApplyTheme(name) {
    global _ThemeMgr
    if IsObject(_ThemeMgr)
        _ThemeMgr.Apply(name)
}

; Cycles to the next theme. To be used as event callback.
CycleTheme(state, ctrl, event) {
    global _ThemeMgr
    if IsObject(_ThemeMgr)
        _ThemeMgr.Next()
}

; Returns the current 1-based theme index within the active subset.
GetThemeIndex() {
    global _ThemeMgr
    return IsObject(_ThemeMgr) ? _ThemeMgr.index : 1
}

; Returns the current theme name string.
GetCurrentTheme() {
    global _ThemeMgr
    return IsObject(_ThemeMgr) ? _ThemeMgr.CurrentName() : ""
}

; ======================================================================
; INTERNAL CLASS
; ======================================================================
class _ThemeManagerCore {
    ui := ""
    index := 1
    subset := []

    __New(ui, subset) {
        this.ui := ui
        this.subset := subset
        global ThemeDefs
    }

    ; Apply a theme by name
    Apply(name) {
        global ThemeDefs
        ui := this.ui

        ; Validate theme exists
        if !ThemeDefs.HasKey(name) {
            if (this.subset.Length() > 0)
                name := this.subset[1]
            else
                return
        }

        ; Sync index to match the applied theme name
        this._SyncIndex(name)

        def := ThemeDefs[name]

        ; Always set the base theme
        ui.SetTheme(def.base)

        ; Apply all color resources (skip 'base')
        for key, color in def {
            if (key = "base")
                continue
            ui.SetResource(key, color)
        }

        ; Set window background if defined
        if def.HasKey("WindowBg")
            ui.SetWindowProp("Background", def.WindowBg)

        ; Update theme button (silently skip if button doesn't exist)
        ui.Update("BtnTheme", "Content", name)
    }

    ; Cycle to next theme
    Next() {
        this.index++
        if (this.index > this.subset.Length())
            this.index := 1
        this.Apply(this.subset[this.index])
    }

    ; Get current theme name
    CurrentName() {
        if (this.index < 1 || this.index > this.subset.Length())
            return ""
        return this.subset[this.index]
    }

    ; Internal: synchronize this.index to match a given theme name
    _SyncIndex(name) {
        Loop, % this.subset.Length() {
            if (this.subset[A_Index] = name) {
                this.index := A_Index
                return
            }
        }
        this.index := 1
    }
}
