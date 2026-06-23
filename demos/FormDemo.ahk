#NoEnv
SetBatchLines, -1
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#SINGLEINSTANCE FORCE

global ui := new XAMLGUI(A_ScriptDir "\FormDemo.xaml")

ui.OnEvent("BtnBuild", "Click", "OnBuild")
ui.OnEvent("BtnResetForm", "Click", "OnResetForm")
ui.OnEvent("BtnClose", "Click", "OnClose")
ui.OnEvent("FormView", "Submit", "OnFormSubmit")

ui.Show()
return

OnBuild(state, ctrl, event)
{
    global ui
    def := state["DefEditor"]
    ui.Update("FormView", "Title", "Contact Form")
    ui.Update("FormView", "Define", def)
}

OnResetForm(state, ctrl, event)
{
    global ui
    ui.Update("FormView", "Reset", "")
}

OnFormSubmit(state, ctrl, event)
{
    Global ui
    name  := state["Name"]
    email := state["Email"]
    country := state["Country"]
    age   := state["Age"]
    terms := state["Terms"]
    startDate := state["StartDate"]
    notes := state["Notes"]

    msg := "Name: " name "`n"
    msg .= "Email: " email "`n"
    msg .= "Country: " country "`n"
    msg .= "Age: " age "`n"
    msg .= "Terms accepted: " terms "`n"
    msg .= "Start: " startDate "`n"
    msg .= "Notes: " notes
    global ui
    ui.Msgbox("Form Submitted", msg, "info")
}

OnClose(state, ctrl, event)
{
    ui.Close()
    ExitApp
}
