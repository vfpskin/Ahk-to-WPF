@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo Building WPF_Runner.exe with MsgBox, InputBox, ComboBox, DataGrid, ListView, Enter event, custom controls...
echo.

set CSC_PATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe
set WPFPATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\WPF
set FWPATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319
set LOG_PATH=%~dp0compile_error.log

if not exist "!CSC_PATH!" (
    echo ERROR: csc.exe not found at !CSC_PATH!
    pause
    exit /b 1
)

set REFS=/reference:"!WPFPATH!\PresentationFramework.dll" /reference:"!WPFPATH!\PresentationCore.dll" /reference:"!WPFPATH!\WindowsBase.dll" /reference:"!FWPATH!\System.Xaml.dll" /reference:"!FWPATH!\System.Drawing.dll"

set SOURCES=Program_WPF.cs

if exist "System.Windows.Controls.DataVisualization.Toolkit.dll" set REFS=!REFS! /reference:System.Windows.Controls.DataVisualization.Toolkit.dll
if exist "System.Windows.Controls.DataVisualization.Toolkit.dll" set SOURCES=!SOURCES! ChartControl.cs

if exist "Tesseract.dll" set REFS=!REFS! /reference:Tesseract.dll
if exist "Tesseract.dll" set SOURCES=!SOURCES! OcrControl.cs

if exist "PDFiumSharp.dll" set REFS=!REFS! /reference:PDFiumSharp.dll
if exist "PDFiumSharp.dll" set SOURCES=!SOURCES! IPdfEngine.cs DummyPdfEngine.cs PdfiumEngine.cs PdfViewerControl.cs

echo Compiling...
"!CSC_PATH!" /target:winexe /out:WPF_Runner.exe !SOURCES! !REFS! > "!LOG_PATH!" 2>&1

if %ERRORLEVEL% equ 0 (
    del "!LOG_PATH!" 2>nul
    echo.
    echo ========================================
    echo   BUILD SUCCESSFUL
    echo ========================================
    echo Features included:
    echo   - Events: Click, TextChanged, SelectionChanged, Enter, etc.
    echo   - DataGrid: AddItem, AddColorItem, Clear, RefreshGrid, SetColVisibility
    echo   - ListView: AddItem, AddRow, ClearItems, RemoveSelected, UpdateSelected
    echo   - ComboBox: AddItem, ClearItems, _SelectedIndex, _Text
    echo   - MsgBox: overlay, SweetAlert-style icons, custom buttons
    echo   - InputBox: modal text input with theme support
    if exist "System.Windows.Controls.DataVisualization.Toolkit.dll" echo   - ChartControl
    if exist "Tesseract.dll" echo   - OcrControl (Tesseract)
    if exist "PDFiumSharp.dll" echo   - PdfiumEngine (PDF)
    echo.
    dir WPF_Runner.exe
) else (
    echo.
    echo ========================================
    echo   BUILD ERROR (Code: %ERRORLEVEL%)
    echo ========================================
    echo Log saved to: !LOG_PATH!
    echo.
    echo --- First lines of error ---
    type "!LOG_PATH!"
)

echo.
pause
