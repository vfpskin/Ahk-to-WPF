![Logo](https://github.com/vfpskin/Ahk-to-WPF/raw/main/Assets/logo.png)

# AHK → WPF

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

This project shows how to connect **AutoHotkey 1.1** scripts with a **WPF interface** using the custom `XAMLGUI` engine and bridge `WPF_Runner.exe`.  
It allows you to build modern Windows interfaces while keeping the simplicity and automation power of AHK.

---

## 🚀 Features
- Event handling with `ui.OnEvent()`
- Dynamic UI updates using `ui.Update()`
- Full CRUD operations in `ListView` and `DataGrid`
- Focus control with `ui.Focus()`
- Theme and resource management (`ui.SetTheme()`, `ui.SetResource()`)
- Custom window styling (Dashboard-style header)
- **FIFA Dashboard** — 7-tab management interface with SQLite database, custom themes, and player/stadium/match CRUD via DataGrid
- **SystemInfo Dashboard** — Real-time system information reader parsing `systeminfo` with a 6-card modern layout (System, Processor, Memory, Storage, Network, Extra Info)

---

## 🧠 How It Works
1. **WPF Interface** defines controls with `x:Name`.
2. **AHK Script** loads the XAML file using:
   ```ahk
   ui := new XAMLGUI("Demo_Login.xaml")
   ui.OnEvent("BtnLogin", "Click", "Login_Event")
   ui.Show()
   ```

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
   ```

5. **Requirements**
   Windows 7 or later
   AutoHotkey 1.1+
   .NET Framework 4.0+
   WPF runtime (included in Windows)    

## ⚙️ Compilation

**Program_WPF.cs** — The C# entry point for the WPF application. It initializes the runtime and loads the XAML interface.

**compile_WPF_Runner.bat** — Batch script that automates compilation using the .NET Framework compiler (`csc.exe`).  
⚠️ **Important:** The path to `csc.exe` may vary depending on your system configuration.  
- On most Windows installations it is located under:  
  `C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe`  
- If you have a different version of .NET installed, adjust the path in the BAT file accordingly.  
- Example modification inside the BAT script:  
  ```bat
  "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" ^
  /target:winexe ^
  /out:WPF_Runner.exe ^
  /reference:"C:\Windows\Microsoft.NET\Framework\v4.0.30319\WPF\PresentationFramework.dll" ^
  /reference:"C:\Windows\Microsoft.NET\Framework\v4.0.30319\WPF\PresentationCore.dll" ^
  /reference:"C:\Windows\Microsoft.NET\Framework\v4.0.30319\WPF\WindowsBase.dll" ^
  Program_WPF.cs
  ```
- If compilation fails with **CS0006 errors**, double-check that the DLL references exist in your system and update the paths accordingly.

## 📦 Precompiled Executable
For users who prefer not to compile the project manually, a precompiled executable is provided in a `.zip` archive inside the `release/` folder:

➡️ **[Download WPF_Runner.zip](https://github.com/vfpskin/Ahk-to-WPF/releases/tag/v1.0.0)**

It contains the compiled WPF runner (`WPF_Runner.exe`) built from `Program_WPF.cs`, so you can run the demos without configuring `csc.exe` or editing the batch script.

⚠️ Note: The executable was compiled on Windows 7 (32-bit) with .NET Framework 4.0.

If the `.exe` does not run on your system, this is likely the reason.
However, compiling in 32-bit mode generally increases compatibility across different Windows versions and distributions.
If you encounter issues, you can recompile using `compile_WPF_Runner.bat` and adjust the path to your local `csc.exe`.
   

## **Credits**
Created (vibe coded) by Vfpskin (Pablo Molina) 
Logo and diagrams designed with Microsoft Copilot© 2026 — All rights reserved

## **License**
MIT License — free to use and modify with attribution.   
