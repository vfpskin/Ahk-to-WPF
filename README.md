![Logo](https://github.com/vfpskin/Ahk-to-WPF/raw/main/Assets/logo.png)

# AHK → WPF

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

This project shows how to connect **AutoHotkey 1.1** scripts with a **WPF interface** using the custom `XAMLGUI` engine and bridge `WPF_Runner.exe`.  
It allows you to build modern Windows interfaces while keeping the simplicity and automation power of AHK.

---

## 🚀 Features
- Event handling with `ui.OnEvent()` — supports 15+ control types including Button, TextBox, PasswordBox, CheckBox, RadioButton, ToggleButton, RepeatButton, Slider, ScrollBar, DatePicker, Calendar, ComboBox, ListView, DataGrid, TabControl, Hyperlink
- Dynamic UI updates using `ui.Update()` — over 25 supported properties (Text, Content, Value, Margin, Visibility, Background, Foreground, FontSize, and more)
- Full CRUD operations in `ListView` and `DataGrid`
- Focus control with `ui.Focus()`
- Theme and resource management (`ui.SetTheme()`, `ui.SetResource()`) — 9 built-in themes
- Custom window styling (Dashboard-style header, drag-to-move, minimize/maximize/close)
- Modern control templates for ToggleButton (switch), CheckBox, RadioButton, ProgressBar, Slider, ScrollBar
- **All Controls Demo** — comprehensive 5-tab demo covering 15+ controls with bidirectional AHK ↔ WPF communication
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

⚠️ Note: The executable is compiled as **AnyCPU** with the 32-bit .NET Framework 4.x compiler (`csc.exe`). It runs natively on both 32-bit and 64-bit Windows systems with .NET Framework 4.0 or later.

If the `.exe` does not run on your system, recompile using `compile_WPF_Runner.bat` and adjust the `csc.exe` path to match your .NET installation.
   
    
## 🎮 Demos Included
All demos are in the `demos/` folder. Run any `.ahk` file to launch its WPF interface.

| Demo | File | Description |
|------|------|-------------|
| **All Controls** | `Demo_AllControls.ahk` | 5-tab comprehensive demo with 15+ controls, theme cycling, circle positioning |
| **Login Animation** | `Demo_Animation_Login.ahk` | Animated overlay login with fade effects |
| **FIFA Dashboard** | `Demo_Dashboard_FIFA.ahk` | Full sports management dashboard with SQLite |
| **SystemInfo** | `Demo_SystemInfo.ahk` | Real-time system info reader with 6-card layout |

## **Credits**
Created (vibe coded) by Vfpskin (Pablo Molina) 
Logo and diagrams designed with Microsoft Copilot© 2026 — All rights reserved

## **License**
MIT License — free to use and modify with attribution.   
