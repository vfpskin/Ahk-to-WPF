#NoEnv
SetBatchLines, -1
#SingleInstance Force
#Include %A_ScriptDir%\..\XAMLGUI.ahk
#Include %A_ScriptDir%\..\TitleBar.ahk

; ======================================================================
; INVENTORY DATA DASHBOARD DEMO - DATAGRID CRUD APPLICATION
; ======================================================================
global ui := new XAMLGUI(A_ScriptDir "\Demo_DataGrid.xaml")

; Global Data Stores
global InventoryList   := []    ; Array storing item objects: {ID, Name, Category, Stock, Price}
global SelectedRowIdx  := -1    ; Tracks row Selection index inside the DataGrid (0-based from state)
global ActiveEditIdx   := -1    ; Pointer to item ID currently being modified (-1 = New Mode)
global TargetActionIdx := -1    ; Remembers contextual index when handling multi-choice DoubleClick dialogs
global ConfigFile    := A_ScriptDir "\inventory_db.ini"

; 1. Load historical records from .ini file into memory
LoadDatabase()

; 2. Initialize title bar
InitTitleBar(ui, {title: "Inventory Dashboard", onClose: "OnBtnClose"})

; Map Component Core Events
ui.OnEvent("BtnSave",       "Click",            "OnBtnSave")
ui.OnEvent("BtnModify",     "Click",            "OnBtnModify")
ui.OnEvent("BtnDelete",     "Click",            "OnBtnDelete")
ui.OnEvent("BtnSample",     "Click",            "OnBtnSample")
ui.OnEvent("GridInventory", "SelectionChanged", "OnGridSelection")
ui.OnEvent("GridInventory", "MouseDoubleClick", "OnGridDoubleClick")

; Map Flow Controls for Form Fields (Carries focus forward on pressing Enter)
ui.OnEvent("TxtName",     "Enter", "OnFieldEnter")
ui.OnEvent("TxtCategory", "Enter", "OnFieldEnter")
ui.OnEvent("TxtStock",    "Enter", "OnFieldEnter")
ui.OnEvent("TxtPrice",    "Enter", "OnFieldEnter")

; Map Custom Notification Overlay Responses
ui.OnEvent("BtnSA_OK",   "Click", "OnModalResponse")
ui.OnEvent("BtnSA_Yes",  "Click", "OnModalResponse")
ui.OnEvent("BtnSA_No",   "Click", "OnModalResponse")

ui.Show()
; Inject loaded data into DataGrid and update metrics
RenderDataGrid()
EvaluateMetrics()
return











return

; ======================================================================
; DATABASE STORAGE MANAGEMENT
; ======================================================================
SaveDatabase()
{
    global InventoryList, ConfigFile
    
    ; Delete previous file to avoid remnants of deleted products
    if (FileExist(ConfigFile))
        FileDelete, %ConfigFile%
        
    total := InventoryList.Length()
    IniWrite, %total%, %ConfigFile%, Settings, TotalItems
    
    for idx, item in InventoryList
    {
        sec := "Product_" . idx
        IniWrite, % item.ID, %ConfigFile%, %sec%, ID
        IniWrite, % item.Name, %ConfigFile%, %sec%, Name
        IniWrite, % item.Category, %ConfigFile%, %sec%, Category
        IniWrite, % item.Stock, %ConfigFile%, %sec%, Stock
        IniWrite, % item.Price, %ConfigFile%, %sec%, Price
    }
}

BootDatabase()
{
    global InventoryList, DatabaseFile
    if (!FileExist(DatabaseFile))
    {
        ; Seed initial mockup products if database is empty
        InventoryList.Push({ID: 101, Name: "Intel Core i7-13700K", Category: "Processors", Stock: 14, Price: 389.99})
        InventoryList.Push({ID: 102, Name: "NVIDIA RTX 4070 Ti", Category: "Graphics Cards", Stock: 8, Price: 799.50})
        InventoryList.Push({ID: 103, Name: "Corsair Vengeance 32GB DDR5", Category: "Memory", Stock: 25, Price: 115.00})
        SaveDatabase()
    }
    else
    {
        IniRead, sectionText, %DatabaseFile%, Products
        Loop, Parse, sectionText, `n, `r
        {
            if (Trim(A_LoopField) = "")
                continue
            
            eqPos := InStr(A_LoopField, "=")
            itemID := SubStr(A_LoopField, 1, eqPos - 1)
            recordData := SubStr(A_LoopField, eqPos + 1)
            
            StringSplit, fields, recordData, |
            InventoryList.Push({ID: itemID + 0, Name: fields1, Category: fields2, Stock: fields3 + 0, Price: fields4 + 0.0})
        }
    }
    
    RenderDataGrid()
    EvaluateMetrics()
}

; ======================================================================
; INTERACTION FLOW & INPUT PROCESSING
; ======================================================================
OnFieldEnter(state, ctrl, event)
{
    global ui
    if (ctrl = "TxtName")
        ui.Focus("TxtCategory")
    else if (ctrl = "TxtCategory")
        ui.Focus("TxtStock")
    else if (ctrl = "TxtStock")
        ui.Focus("TxtPrice")
    else if (ctrl = "TxtPrice")
        OnBtnSave(state, "BtnSave", "Click")
}

OnGridSelection(state, ctrl, event)
{
    global ui, SelectedRowIdx, ActiveEditIdx
    
    ; Use the direct selected index from the DataGrid (more reliable than searching by ID)
    rawIdx := state["GridInventory_SelectedIndex"]
    
    if (rawIdx = "" || rawIdx < 0)
    {
        SelectedRowIdx := -1
        if (ActiveEditIdx <= 0)
        {
            ui.Update("BtnModify", "IsEnabled", "False")
            ui.Update("BtnDelete", "IsEnabled", "False")
        }
        return
    }
    
    SelectedRowIdx := rawIdx + 0
    
    ; If actively editing, don't alter the buttons below
    if (ActiveEditIdx > 0)
        return
        
    ; If row found successfully, enable the buttons immediately
    if (SelectedRowIdx >= 0)
    {
        ui.Update("BtnModify", "IsEnabled", "True")
        ui.Update("BtnDelete", "IsEnabled", "True")
    }
    else
    {
        ui.Update("BtnModify", "IsEnabled", "False")
        ui.Update("BtnDelete", "IsEnabled", "False")
    }
}


OnGridSelection_old(state, ctrl, event)
{
    global ui, SelectedRowIdx, ActiveEditIdx
    
    ; DataGrid exposes selection row context inside its dedicated attribute field
    rawIdx := state["GridInventory_SelectedIndex"]
    
    if (rawIdx = "" || rawIdx < 0)
    {
        SelectedRowIdx := -1
    }
    else
    {
        SelectedRowIdx := rawIdx + 0
    }
    
    ; Prevent mutating selection modifiers while an item form is actively being edited
    if (ActiveEditIdx > 0)
        return
        
    isRowSelected := (SelectedRowIdx >= 0) ? "True" : "False"
    ui.Update("BtnModify", "IsEnabled", isRowSelected)
    ui.Update("BtnDelete", "IsEnabled", isRowSelected)
}

; ======================================================================
; CORE CRUD IMPLEMENTATIONS
; ======================================================================
OnBtnSave(state, ctrl, event)
{
    global ui, InventoryList, ActiveEditIdx, SelectedRowIdx
    
    prodName := Trim(state["TxtName"])
    category := Trim(state["TxtCategory"])
    rawStock := Trim(state["TxtStock"])
    rawPrice := Trim(state["TxtPrice"])
    
    ; Input Field Validations
    if (prodName = "" || category = "")
    {
        TriggerModalAlert("Missing Information", "Please enter both the Product Name and Category fields.", "warning")
        return
    }
    if rawStock is not integer
    {
        TriggerModalAlert("Data Format Error", "Stock inventory level must be a whole numerical integer value.", "error")
        return
    }
    if rawPrice is not number
    {
        TriggerModalAlert("Data Format Error", "Unit price must resolve to a valid numeric amount.", "error")
        return
    }
    
    if (ActiveEditIdx > 0)
    {
        ; Handle Modification Save Protocol
        for idx, item in InventoryList
        {
            if (item.ID = ActiveEditIdx)
            {
                InventoryList[idx] := {ID: ActiveEditIdx, Name: prodName, Category: category, Stock: rawStock + 0, Price: rawPrice + 0.0}
                break
            }
        }
        ActiveEditIdx := -1
        ui.Update("BtnSave", "Content", "+ Save Product")
    }
    else
    {
        ; Handle Creation Generation Protocol
        Random, newID, 5000, 9999
        InventoryList.Push({ID: newID, Name: prodName, Category: category, Stock: rawStock + 0, Price: rawPrice + 0.0})
    }
    
    SaveDatabase()
    RenderDataGrid()
    
    ; Form UI Flush Reset Sequence
    ui.Update("TxtName", "Text", "")
    ui.Update("TxtCategory", "Text", "")
    ui.Update("TxtStock", "Text", "")
    ui.Update("TxtPrice", "Text", "")
    ui.Focus("TxtName")
    
    SelectedRowIdx := -1
    ui.Update("BtnModify", "IsEnabled", "False")
    ui.Update("BtnDelete", "IsEnabled", "False")
    EvaluateMetrics()
}

OnBtnModify(state, ctrl, event)
{
    global InventoryList, SelectedRowIdx, ui, ActiveEditIdx
    targetIndex := SelectedRowIdx + 1 ; Compensate for 0-indexed values mapping to 1-based lists
    
    if (targetIndex < 1 || targetIndex > InventoryList.Length())
        return
        
    targetItem := InventoryList[targetIndex]
    
    ; Fill text fields with the object property definitions
    ui.Update("TxtName", "Text", targetItem.Name)
    ui.Update("TxtCategory", "Text", targetItem.Category)
    ui.Update("TxtStock", "Text", targetItem.Stock)
    ui.Update("TxtPrice", "Text", targetItem.Price)
    
    ActiveEditIdx := targetItem.ID
    ui.Update("BtnSave", "Content", "💾 Update Record")
    ui.Update("BtnModify", "IsEnabled", "False")
    ui.Update("BtnDelete", "IsEnabled", "False")
}

OnBtnDelete(state, ctrl, event)
{
    global InventoryList, SelectedRowIdx
    targetIndex := SelectedRowIdx + 1
    
    if (targetIndex < 1 || targetIndex > InventoryList.Length())
        return
        
    TriggerModalConfirm("Verify Deletion", "Are you sure you want to permanently remove '" . InventoryList[targetIndex].Name . "' from the records?", "ExecuteDeletionProcedure")
}

ExecuteDeletionProcedure()
{
    global InventoryList, SelectedRowIdx, ui
    targetIndex := SelectedRowIdx + 1
    
    if (targetIndex < 1 || targetIndex > InventoryList.Length())
        return
        
    ; 1. Disable buttons preventively
    ui.Update("BtnModify", "IsEnabled", "False")
    ui.Update("BtnDelete", "IsEnabled", "False")
    
    ; 2. Force DataGrid to remove selection before deletion
    ui.Update("GridInventory", "SelectedIndex", "-1")
    
    ; 3. Now safely delete from memory
    InventoryList.RemoveAt(targetIndex)
    SelectedRowIdx := -1
    
    ; 4. Guardamos y refrescamos la pantalla
    SaveDatabase()
    RenderDataGrid()
    EvaluateMetrics()
}

; ======================================================================
; HOOKS FOR DOUBLE-CLICK MODAL ACTIONS
; ======================================================================
OnGridDoubleClick(state, ctrl, event)
{
    global InventoryList, TargetActionIdx
    
    ; Grid context row capture via specific click-event tracking tags
    clickIndex := state["GridInventory_EventRowIndex"]
    
    if (clickIndex = "" || clickIndex < 0)
        return
        
    mappedIdx := clickIndex + 1
    if (mappedIdx < 1 || mappedIdx > InventoryList.Length())
        return
        
    TargetActionIdx := mappedIdx
    TriggerModalSplitOptions("Row Quick Actions", "What operations would you like to execute for product '" . InventoryList[mappedIdx].Name . "'?")
}

TriggeredEditFlow()
{
    global SelectedRowIdx, TargetActionIdx
    SelectedRowIdx := TargetActionIdx - 1
    OnBtnModify("", "", "")
}

TriggeredDeleteFlow()
{
    global SelectedRowIdx, TargetActionIdx
    SelectedRowIdx := TargetActionIdx - 1
    OnBtnDelete("", "", "")
}

; ======================================================================
; RENDER ENGINE AND COMPONENT HELPERS
; ======================================================================
RenderDataGrid()
{
    global InventoryList, ui
    
    ; 1. Clear the grid completely
    ui.Update("GridInventory", "Clear", "")
    
    ; 2. Iterate inventory to populate rows and their corresponding colors
    for idx, item in InventoryList
    {
        ; Send raw data
        rowPacket := item.ID . "|" . item.Name . "|" . item.Category . "|" . item.Stock . "|" . item.Price
        ui.Update("GridInventory", "AddItem", rowPacket)
        
        ; --- Prepare default color variables (Empty = No special color) ---
        cID       := ""
        cName     := ""
        cCategory := ""
        cStock    := ""
        cPrice    := ""
        
        ; RULE 1: Stock lower than 20 -> Stock cell Pastel Red Background
        if (item.Stock < 20)
        {
            cStock := "#FADBD8"
        }
        
        ; RULE 2: Colors by category in the Category cell
        catUpper := Format("{:U}", Trim(item.Category))
        if (catUpper = "FURNITURE")
        {
            cCategory := "#FCF3CF" ; Amarillo pastel
        }
        else if (catUpper = "OFFICE")
        {
            cCategory := "#D4EFDF" ; Verde pastel
        }
        else if (catUpper = "BOOKSHOP")
        {
            cCategory := "#F8BBD0" ; Rosa pastel
        }
        else if (catUpper = "ELECTRONICS")
        {
            cCategory := "#D4E6F1" ; Azul pastel
        }
        
        ; Join the color package respecting the exact column order of the DataGrid
        rowColor := cID . "|" . cName . "|" . cCategory . "|" . cStock . "|" . cPrice
        
        ; If at least one color is defined, send it to the WPF engine
        if (cStock != "" || cCategory != "")
        {
            ui.Update("GridInventory", "AddColorItem", rowColor)
        }
    }

    ; Column alignment: name_or_index | Left/Center/Right
    ui.Update("GridInventory", "SetColAlignment", "ID|Center")
    ui.Update("GridInventory", "SetColAlignment", "Stock|Center")
    ui.Update("GridInventory", "SetColAlignment", "Price|Center")
}

EvaluateMetrics()
{
    global ui, InventoryList
    totalCount := InventoryList.Length()
    ui.Update("LblMetrics", "Text", (totalCount = 1 ? "1 product item currently cataloged" : totalCount . " unique product items cataloged"))
}

; ======================================================================
; SAMPLE DATA GENERATOR
; ======================================================================
global SampleIdCounter := 200

OnBtnSample(state, ctrl, event)
{
    global ui, InventoryList, SampleIdCounter

    sampleData := []
    sampleData.Push({Name: "Gaming Chair",    Category: "Furniture",    Stock: 10, Price: 349.99})
    sampleData.Push({Name: "Office Desk",     Category: "Furniture",    Stock: 5,  Price: 599.99})
    sampleData.Push({Name: "Mechanical KB",   Category: "Electronics",  Stock: 30, Price: 149.99})
    sampleData.Push({Name: "Notebook A5",     Category: "Bookshop",     Stock: 100,Price: 4.99})
    sampleData.Push({Name: "Monitor 27""",     Category: "Electronics",  Stock: 8,  Price: 399.99})
    sampleData.Push({Name: "Standing Desk",   Category: "Furniture",    Stock: 15, Price: 899.99})
    sampleData.Push({Name: "Office Chair",    Category: "Furniture",    Stock: 22, Price: 259.99})
    sampleData.Push({Name: "USB-C Hub",       Category: "Electronics",  Stock: 45, Price: 39.99})
    sampleData.Push({Name: "Stapler",         Category: "Office",       Stock: 60, Price: 12.50})
    sampleData.Push({Name: "Whiteboard",      Category: "Office",       Stock: 3,  Price: 89.99})

    for i, item in sampleData
    {
        item.ID := ++SampleIdCounter
        InventoryList.Push(item)
    }

    RenderDataGrid()
    EvaluateMetrics()
    ui.Update("SweetAlertOverlay", "Visibility", "Collapsed")
}

OnBtnClose(state, ctrl, event)
{
    global ui
    SaveDatabase()
    ui.Close()
    Sleep, 100 ; Give memory a brief moment to unload COM threads
    ExitApp
}

OnBtnClose_old(state, ctrl, event)
{
    global ui
    SaveDatabase()
    ui.Close()
    ExitApp
}

; ======================================================================
; CUSTOM NOTIFICATION MODAL ROUTINES (SWEETALERT ENGINE)
; ======================================================================
global ModalSuccessCallback := ""
global ModalFailureCallback := ""

TriggerModalAlert(title, message, visualIcon:="info", returnCallback:="")
{
    global ui, ModalSuccessCallback, ModalFailureCallback
    ModalSuccessCallback := returnCallback
    ModalFailureCallback := ""
    
    ui.Update("SA_TxtTitle", "Text", title)
    ui.Update("SA_TxtMessage", "Text", message)
    
    ui.Update("SA_IcoInfo", "Visibility", (visualIcon="info"?"Visible":"Collapsed"))
    ui.Update("SA_IcoSuccess", "Visibility", (visualIcon="success"?"Visible":"Collapsed"))
    ui.Update("SA_IcoError", "Visibility", (visualIcon="error"?"Visible":"Collapsed"))
    ui.Update("SA_IcoWarning", "Visibility", (visualIcon="warning"?"Visible":"Collapsed"))
    
    ui.Update("BtnSA_OK", "Content", "OK")
    ui.Update("BtnSA_OK", "Visibility", "Visible")
    ui.Update("BtnSA_Yes", "Visibility", "Collapsed")
    ui.Update("BtnSA_No", "Visibility", "Collapsed")
    ui.Update("SweetAlertOverlay", "Visibility", "Visible")
    ui.Focus("BtnSA_OK")
}

TriggerModalConfirm(title, message, affirmativeCallback:="")
{
    global ui, ModalSuccessCallback, ModalFailureCallback
    ModalSuccessCallback := affirmativeCallback
    ModalFailureCallback := ""
    
    ui.Update("SA_TxtTitle", "Text", title)
    ui.Update("SA_TxtMessage", "Text", message)
    
    ui.Update("SA_IcoInfo", "Visibility", "Collapsed")
    ui.Update("SA_IcoSuccess", "Visibility", "Collapsed")
    ui.Update("SA_IcoError", "Visibility", "Collapsed")
    ui.Update("SA_IcoWarning", "Visibility", "Visible")
    
    ui.Update("BtnSA_Yes", "Content", "Yes, Proceed")
    ui.Update("BtnSA_No", "Content", "Cancel")
    ui.Update("BtnSA_OK", "Visibility", "Collapsed")
    ui.Update("BtnSA_Yes", "Visibility", "Visible")
    ui.Update("BtnSA_No", "Visibility", "Visible")
    ui.Update("SweetAlertOverlay", "Visibility", "Visible")
    ui.Focus("BtnSA_Yes")
}

TriggerModalSplitOptions(title, message)
{
    global ui, ModalSuccessCallback, ModalFailureCallback
    ModalSuccessCallback := "TriggeredEditFlow"
    ModalFailureCallback := "TriggeredDeleteFlow"
    
    ui.Update("SA_TxtTitle", "Text", title)
    ui.Update("SA_TxtMessage", "Text", message)
    
    ui.Update("SA_IcoInfo", "Visibility", "Visible")
    ui.Update("SA_IcoSuccess", "Visibility", "Collapsed")
    ui.Update("SA_IcoError", "Visibility", "Collapsed")
    ui.Update("SA_IcoWarning", "Visibility", "Collapsed")
    
    ui.Update("BtnSA_Yes", "Content", "Modify Item")
    ui.Update("BtnSA_No", "Content", "Delete Item")
    ui.Update("BtnSA_OK", "Visibility", "Collapsed")
    ui.Update("BtnSA_Yes", "Visibility", "Visible")
    ui.Update("BtnSA_No", "Visibility", "Visible")
    ui.Update("SweetAlertOverlay", "Visibility", "Visible")
    ui.Focus("BtnSA_Yes")
}

OnModalResponse(state, ctrl, event)
{
    global ui, ModalSuccessCallback, ModalFailureCallback
    ui.Update("SweetAlertOverlay", "Visibility", "Collapsed")
    
    if (ctrl = "BtnSA_Yes" && ModalSuccessCallback != "" && IsFunc(ModalSuccessCallback))
    {
        %ModalSuccessCallback%()
    }
    else if (ctrl = "BtnSA_No" && ModalFailureCallback != "" && IsFunc(ModalFailureCallback))
    {
        %ModalFailureCallback%()
    }
}

LoadDatabase()
{
    global InventoryList, ConfigFile
    InventoryList := []
    
    ; If the file doesn't exist, exit with empty array
    if (!FileExist(ConfigFile))
        return
        
    ; Read total number of saved items
    IniRead, totalItems, %ConfigFile%, Settings, TotalItems, 0
    totalItems := totalItems + 0 ; Force numeric type
    
    Loop, % totalItems
    {
        sec := "Product_" . A_Index
        
        ; Leemos cada uno de los campos del producto
        IniRead, id, %ConfigFile%, %sec%, ID, % ""
        IniRead, name, %ConfigFile%, %sec%, Name, % ""
        IniRead, category, %ConfigFile%, %sec%, Category, % ""
        IniRead, stock, %ConfigFile%, %sec%, Stock, 0
        IniRead, price, %ConfigFile%, %sec%, Price, 0
        
        ; If for any reason the ID is empty, ignore this corrupted record
        if (id = "")
            continue
            
        ; Creamos el objeto del producto con sus tipos correctos
        item := {}
        item.ID := id + 0
        item.Name := name
        item.Category := category
        item.Stock := stock + 0
        item.Price := price + 0
        
        ; Lo agregamos a nuestra lista en memoria
        InventoryList.Push(item)
    }
}
