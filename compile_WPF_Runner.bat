@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo Compilando WPF_Runner.exe con soporte para Enter event, TextBlock Click, DataGrid ComboBox...
echo.

set CSC_PATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe
set WPFPATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\WPF
set FWPATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319
set LOG_PATH=%~dp0compile_error.log

if not exist "!CSC_PATH!" (
    echo ERROR: csc.exe no encontrado en !CSC_PATH!
    pause
    exit /b 1
)

echo Compilando...
"!CSC_PATH!" /target:winexe /out:WPF_Runner.exe Program_WPF.cs ^
    /reference:"!WPFPATH!\PresentationFramework.dll" ^
    /reference:"!WPFPATH!\PresentationCore.dll" ^
    /reference:"!WPFPATH!\WindowsBase.dll" ^
    /reference:"!FWPATH!\System.Xaml.dll" ^
    > "!LOG_PATH!" 2>&1

if %ERRORLEVEL% equ 0 (
    del "!LOG_PATH!" 2>nul
    echo.
    echo ========================================
    echo   Compilacion EXITOSA
    echo ========================================
    echo Funcionalidades incluidas:
    echo   - Eventos: Click, TextChanged, SelectionChanged, Enter, etc.
    echo   - DataGrid: AddItem, AddColorItem, Clear, RefreshGrid, SetColVisibility
    echo   - ListView: AddItem, AddRow, ClearItems, RemoveSelected, UpdateSelected
    echo   - ComboBox: AddItem, ClearItems, _SelectedIndex, _Text
    echo.
    dir WPF_Runner.exe
) else (
    echo.
    echo ========================================
    echo   ERROR en compilacion (Codigo: %ERRORLEVEL%)
    echo ========================================
    echo Log guardado en: !LOG_PATH!
    echo.
    echo --- Primeras lineas del error ---
    type "!LOG_PATH!"
)

echo.
pause
