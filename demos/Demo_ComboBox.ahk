#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\themes.ahk
#Include %A_ScriptDir%\..\ThemeManager.ahk

global ui := new XAMLGUI(A_ScriptDir . "\Demo_ComboBox.xaml")

InitThemeManager(ui)
ApplyTheme("Navy")

global _dynItems := []
global _fruitItems := []
global _fruitPool := ["Apple", "Banana", "Cherry", "Grape", "Orange", "Peach", "Strawberry"]

ui.OnEvent("ComboStatic",  "SelectionChanged", "OnComboStatic")
ui.OnEvent("ComboDynamic", "SelectionChanged", "OnComboDynamic")
ui.OnEvent("ComboFruits",  "SelectionChanged", "OnComboFruits")
ui.OnEvent("BtnTheme",     "Click", "OnCycleTheme")
ui.OnEvent("BtnGetSel",    "Click", "OnGetSelections")
ui.OnEvent("BtnClearAll",  "Click", "OnClearAll")
ui.OnEvent("BtnAddFruit",  "Click", "OnAddFruitDyn")
ui.OnEvent("BtnAddColor",  "Click", "OnAddColorDyn")
ui.OnEvent("BtnClearDyn",  "Click", "OnClearDynamic")
ui.OnEvent("BtnAddFruitItem", "Click", "OnAddFruitItem")
ui.OnEvent("BtnClearFruits",  "Click", "OnClearFruits")
ui.OnEvent("BtnSetIdx",    "Click", "OnSetFruitIndex")

if !ui.Show() {
    MsgBox, Failed to load ComboBox Demo.
    ExitApp
}

PopulateFruits()
PopulateDynamic()
ui.Update("LblThemeName", "Text", "Theme: Navy")
ui.Update("LblThemeStatus", "Text", "Navy")
UpdateTotal()
return

PopulateFruits()
{
    global ui, _fruitItems, _fruitPool
    _fruitItems := []
    for i, f in _fruitPool {
        _fruitItems.Push(f)
        ui.Update("ComboFruits", "AddItem", f)
    }
    ui.Update("ComboFruits", "SelectedIndex", "0")
    ui.Update("LblFruits", "Text", "Selected: Apple")
    ui.Update("LblFruitCount", "Text", "Items: " _fruitItems.MaxIndex())
}

PopulateDynamic()
{
    global ui, _dynItems
    _dynItems := ["Option A", "Option B", "Option C"]
    for i, item in _dynItems
        ui.Update("ComboDynamic", "AddItem", item)
    ui.Update("ComboDynamic", "SelectedIndex", "0")
    ui.Update("LblDynamic", "Text", "Selected: Option A")
    ui.Update("LblDynCount", "Text", "Items: " _dynItems.MaxIndex())
}

UpdateTotal()
{
    global ui, _dynItems, _fruitItems
    total := 10 + _dynItems.MaxIndex() + _fruitItems.MaxIndex()
    ui.Update("LblTotalItems", "Text", "Total Items: " total)
}

OnComboStatic(state, ctrl, event)
{
    global ui
    idx := state["ComboStatic_SelectedIndex"]
    txt := state["ComboStatic_Text"]
    if (idx >= 0) {
        ui.Update("LblStatic", "Text", "Selected: " txt)
        ui.Update("LblValStatic", "Text", "ComboStatic: index=" idx ", text=""" txt """")
        ui.Update("LblLastAction", "Text", "Static: " txt)
    }
}

OnComboDynamic(state, ctrl, event)
{
    global ui, _dynItems
    idx := state["ComboDynamic_SelectedIndex"]
    txt := state["ComboDynamic_Text"]
    if (idx >= 0 && idx < _dynItems.MaxIndex()) {
        _dynItems[idx + 1] := txt
        ui.Update("LblDynamic", "Text", "Selected: " txt)
        ui.Update("LblValDynamic", "Text", "ComboDynamic: index=" idx ", text=""" txt """")
        ui.Update("LblLastAction", "Text", "Dynamic: " txt)
    }
}

OnComboFruits(state, ctrl, event)
{
    global ui, _fruitItems
    idx := state["ComboFruits_SelectedIndex"]
    txt := state["ComboFruits_Text"]
    if (idx >= 0 && idx < _fruitItems.MaxIndex()) {
        _fruitItems[idx + 1] := txt
        ui.Update("LblFruits", "Text", "Selected: " txt)
        ui.Update("LblValFruits", "Text", "ComboFruits: index=" idx ", text=""" txt """")
        ui.Update("LblLastAction", "Text", "Fruits: " txt)
    }
}

OnCycleTheme(state, ctrl, event)
{
    global ui
    CycleTheme(state, ctrl, event)
    c := GetCurrentTheme()
    ui.Update("LblThemeName", "Text", "Theme: " c)
    ui.Update("LblThemeStatus", "Text", c)
    ui.Update("LblLastAction", "Text", "Theme: " c)
}

OnGetSelections(state, ctrl, event)
{
    global ui
    sIdx := state["ComboStatic_SelectedIndex"]
    sTxt := state["ComboStatic_Text"]
    dIdx := state["ComboDynamic_SelectedIndex"]
    dTxt := state["ComboDynamic_Text"]
    fIdx := state["ComboFruits_SelectedIndex"]
    fTxt := state["ComboFruits_Text"]
    ui.Update("LblValStatic", "Text", "ComboStatic: index=" sIdx ", text=""" sTxt """")
    ui.Update("LblValDynamic", "Text", "ComboDynamic: index=" dIdx ", text=""" dTxt """")
    ui.Update("LblValFruits", "Text", "ComboFruits: index=" fIdx ", text=""" fTxt """")
    ui.Update("LblLastAction", "Text", "All selections refreshed")
}

OnClearAll(state, ctrl, event)
{
    global ui
    ui.Update("ComboStatic", "SelectedIndex", "-1")
    ui.Update("ComboDynamic", "SelectedIndex", "-1")
    ui.Update("ComboFruits", "SelectedIndex", "-1")
    ui.Update("LblStatic", "Text", "Selected: -")
    ui.Update("LblDynamic", "Text", "Selected: -")
    ui.Update("LblFruits", "Text", "Selected: -")
    ui.Update("LblValStatic", "Text", "ComboStatic: -")
    ui.Update("LblValDynamic", "Text", "ComboDynamic: -")
    ui.Update("LblValFruits", "Text", "ComboFruits: -")
    ui.Update("LblLastAction", "Text", "All selections cleared")
}

OnAddFruitDyn(state, ctrl, event)
{
    global ui, _dynItems
    static fruits := ["Apple", "Banana", "Cherry", "Dragonfruit", "Elderberry", "Fig", "Grape"]
    static fi := 1
    f := fruits[fi]
    fi := Mod(fi, fruits.MaxIndex()) + 1
    _dynItems.Push(f)
    ui.Update("ComboDynamic", "AddItem", f)
    ui.Update("LblDynCount", "Text", "Items: " _dynItems.MaxIndex())
    ui.Update("LblLastAction", "Text", "Added """ f """ to dynamic combo")
    UpdateTotal()
}

OnAddColorDyn(state, ctrl, event)
{
    global ui, _dynItems
    static colors := ["Red", "Blue", "Green", "Yellow", "Purple", "Orange", "Cyan", "Magenta"]
    static ci := 1
    c := colors[ci]
    ci := Mod(ci, colors.MaxIndex()) + 1
    _dynItems.Push(c)
    ui.Update("ComboDynamic", "AddItem", c)
    ui.Update("LblDynCount", "Text", "Items: " _dynItems.MaxIndex())
    ui.Update("LblLastAction", "Text", "Added """ c """ to dynamic combo")
    UpdateTotal()
}

OnClearDynamic(state, ctrl, event)
{
    global ui, _dynItems
    _dynItems := []
    ui.Update("ComboDynamic", "ClearItems", "")
    ui.Update("LblDynamic", "Text", "Selected: -")
    ui.Update("LblValDynamic", "Text", "ComboDynamic: -")
    ui.Update("LblDynCount", "Text", "Items: 0")
    ui.Update("LblLastAction", "Text", "Dynamic combo cleared")
    UpdateTotal()
}

OnAddFruitItem(state, ctrl, event)
{
    global ui, _fruitItems
    static extras := ["Mango", "Papaya", "Kiwi", "Lemon", "Lime", "Coconut", "Peach", "Plum"]
    static ei := 1
    e := extras[ei]
    ei := Mod(ei, extras.MaxIndex()) + 1
    _fruitItems.Push(e)
    ui.Update("ComboFruits", "AddItem", e)
    ui.Update("LblFruitCount", "Text", "Items: " _fruitItems.MaxIndex())
    ui.Update("LblLastAction", "Text", "Added """ e """ to fruits combo")
    UpdateTotal()
}

OnClearFruits(state, ctrl, event)
{
    global ui, _fruitItems
    _fruitItems := []
    ui.Update("ComboFruits", "ClearItems", "")
    ui.Update("LblFruits", "Text", "Selected: -")
    ui.Update("LblValFruits", "Text", "ComboFruits: -")
    ui.Update("LblFruitCount", "Text", "Items: 0")
    ui.Update("LblLastAction", "Text", "Fruits combo cleared")
    UpdateTotal()
}

OnSetFruitIndex(state, ctrl, event)
{
    global ui, _fruitItems
    if (_fruitItems.MaxIndex() > 2) {
        ui.Update("ComboFruits", "SelectedIndex", "2")
        ui.Update("LblLastAction", "Text", "Fruits SelectedIndex set to 2")
    }
}
