# AHK → WPF Integration

This project shows how to connect **AutoHotkey 1.1** scripts with a **WPF interface** using the custom `XAMLGUI` engine and bridge WPF_Runner.exe.  
It allows you to build modern Windows interfaces while keeping the simplicity and automation power of AHK.

---

## 🚀 Features
- Event handling with `ui.OnEvent()`
- Dynamic UI updates using `ui.Update()`
- Full CRUD operations in `ListView` and `DataGrid`
- Focus control with `ui.Focus()`
- Theme and resource management (`ui.SetTheme()`, `ui.SetResource()`)
- Custom window styling (Dashboard-style header)

---

## 🧠 How It Works
1. **WPF Interface** defines controls with `x:Name`.
2. **AHK Script** loads the XAML file using:
   ```ahk
   ui := new XAMLGUI("Demo_Login.xaml")
   ui.OnEvent("BtnLogin", "Click", "Login_Event")
   ui.Show()


3. **Event Flow:**
   User triggers an event in WPF.
   ui.OnEvent() sends it to AHK.
   AHK processes logic and updates the UI via ui.Update().
   WPF refreshes the interface automatically.
   
4. **Example:**
   ```ahk
    Login_Event(state, ctrl, event)
    {
        user := state["TxtUser"]
        pass := state["TxtPass"]

        if (user = "admin" && pass = "1234")
        {
            ui.Update("TxtStatus", "Text", "Login successful")
            MsgBox, 64, OK, User authorized
        }
        else
        {
            ui.Update("TxtStatus", "Text", "Login error")
            MsgBox, 16, Error, Incorrect credentials
        }
    }   

5. **Requirements**
   Windows 7 or later
   AutoHotkey 1.1+
   .NET Framework 4.0+
   WPF runtime (included in Windows)    
   
## **Credits**
Created (vibe coded) by Vfpskin (Pablo Molina) 
Logo and diagrams designed with Microsoft Copilot© 2026 — All rights reserved

## **License**
MIT License — free to use and modify with attribution.   
