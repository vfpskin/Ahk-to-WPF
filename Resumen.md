# AHK → WPF — Resumen del Proyecto

## Objetivo

Framework modular que conecta **AutoHotkey 1.1** con **WPF (.NET Framework 4.x)** mediante un puente `WPF_Runner.exe` + protocolo `WM_COPYDATA`. Permite construir interfaces modernas con widgets potentes (PDF, charts, QR, OCR, formularios dinámicos) manteniendo la lógica de automatización en AHK.

## Requisitos Técnicos

- **.NET Framework 4.x** exclusivamente (no .NET Core/5+)
- Compilación con `csc.exe` nativo del Framework
- **C# 5** como versión máxima de lenguaje
- Compatible con **Windows 7 x86, Windows 7 x64, Windows 10, Windows 11**
- Sin dependencias externas pesadas (no WebView2, no Edge, no Adobe)
- Sin caracteres acentuados en comentarios de código (inglés obligatorio)

---

## Componentes del Framework

### Base
- **`AhkControlBase`** — clase base para todos los controles personalizados (hereda de `Border`)
  - `SetProperty(prop, val)` — recibe comandos desde AHK
  - `GetValue()` — devuelve estado al AHK
  - `FireEvent(name, extra)` — callback para eventos WPF→AHK
- **`XAMLGUI.ahk`** — engine de comunicación bidireccional con `WM_COPYDATA`
- **`Program_WPF.cs`** — lazo principal, parseo de XAML, enrutamiento de eventos y propiedades

### PDF Viewer
- **`PdfViewerControl`** + **`PdfiumEngine`**
- Motor real con PDFiumSharpV2 (no capturas de pantalla)
- Zoom 10%–400%, navegación por páginas
- PDFium v109.0.5406 (pre-Chromium-110) requerido para Windows 7 x86
- DLLs nativas: `pdfium_x86.dll`, `pdfium_x64.dll`
- Demo: `demos/Prueba.xaml` + `Prueba.ahk`

### Chart Control
- **`ChartControl`**
- WPF Toolkit DataVisualization (`System.Windows.Controls.DataVisualization.Toolkit.dll`)
- Tipos: Column, Line, Pie, Bar, Area, Scatter
- Data: `SetProperty("Data", "label|Cat|Val|...")`
- Demos: `demos/ChartDemo.xaml` (single), `demos/ChartDemo2.xaml` (6 charts grid)

### QR / Barcode
- **`QrControl`**
- ZXing.Net (`zxing.dll`)
- Formatos: QR_CODE, CODE_128, CODE_39, EAN_13
- Exportación: PNG, JPG, BMP, GIF, TIFF
- Demo: `demos/QrDemo.xaml` + `QrDemo.ahk`

### OCR (Tesseract)
- **`OcrControl`**
- Tesseract 5.2.0 (CharlesWeld) + datos español/inglés
- Engine LSTM-only para mejor reconocimiento de acentos
- DLLs nativas en subdirectorios `x86/` y `x64/`
- Idiomas: eng, spa, eng+spa, spa+eng
- Demo: `demos/OcrDemo.xaml` + `OcrDemo.ahk`
- **Observación:** el reconocimiento de caracteres acentuados no es óptimo. Pendiente de mejorar.

### Dynamic Form Builder
- **`FormBuilderControl`**
- Genera formularios dinámicamente desde definición textual
- Tipos: text, password, textarea, number, combo, check, date, radio
- Validaciones: required, rangos numéricos, regex
- Evento `Submit` devuelve todos los valores a AHK
- Demo: `demos/FormDemo.xaml` + `FormDemo.ahk`

### Hello Control
- **`HelloControl`** — control simple de ejemplo/placeholder

---

## APIs de Comunicación

### AHK → WPF
```ahk
ui.Update("CtrlName", "Property", "Value")     ; SetProperty en custom controls
ui.Update("OcrView", "Image", "C:/path.png")   ; ejemplo OCR
ui.Update("OcrView", "Lang", "spa")
ui.Update("FormView", "Define", "type|name|label|...")
```

### WPF → AHK
```csharp
FireEvent("EventName", extraDict);  // desde AhkControlBase
```
```ahk
ui.OnEvent("CtrlName", "EventName", "CallbackFunc")
```

---

## Compilación y Despliegue

- **Script:** `compile_WPF_Runner.bat`
- Usa `csc.exe` de `C:\Windows\Microsoft.NET\Framework\v4.0.30319\`
- Referencia `netstandard.dll` + `System.ValueTuple.dll` para compatibilidad con librerías .NET Standard
- Las DLLs nativas (PDFium, Tesseract) deben estar en el mismo directorio que `WPF_Runner.exe`
- Tesseract requiere subdirectorios `x86/` y `x64/` con las DLLs nativas respectivas
- Datos de idioma en `tessdata/` junto al EXE

## DLLs en Tiempo de Ejecución

| DLL | Propósito | Nativa? |
|-----|-----------|---------|
| `PDFiumSharp.dll` | Wrapper PDFium | No |
| `pdfium_x86.dll` / `pdfium_x64.dll` | Motor PDF | Sí |
| `System.Windows.Controls.DataVisualization.Toolkit.dll` | Charts | No |
| `zxing.dll` | QR/Barcode | No |
| `Tesseract.dll` | Wrapper Tesseract | No |
| `tesseract50.dll` | Motor OCR (x86/ o x64/) | Sí |
| `leptonica-1.82.0.dll` | Procesamiento imágenes (x86/ o x64/) | Sí |

---

## Avances (23-Jun-2026)

### Nuevo: MsgBox modal (`ui.Msgbox()`)
- Overlay SweetAlert-style con iconos (success, error, warning, info, question)
- Botones personalizados: `ui.Msgbox("title", "msg", "warning", "Save|Don't Save|Cancel")`
- Retorno 1, 2, 3... según el botón presionado (posición 1-based)
- Detecta automáticamente `Margin` y `CornerRadius` del contenido vía `InferContentShape()`
- Botones redondeados con `MakeButtonStyle()` + `ControlTemplate` con `CornerRadius=8`
- Demo: `demos/NewDemoAlert.ahk` + `.xaml` (reemplaza `Demo_Alerts`)

### Nuevo: InputBox modal (`ui.InputBox()`)
- `ui.InputBox(title, message, defaultText="")` — overlay con TextBox, OK/Cancel
- Resultado escrito a archivo temporal (`AHK_WPF_Input_{id}.txt`), leído por AHK
- Hereda el tema activo; fondo oscuro semitransparente
- Demo en `NewDemoAlert.ahk`

### Overlay corregido (MsgBox + InputBox)
- `Border` con `ZIndex=500` en lugar de cambiar `root.Background`
- `InferContentShape()` detecta `Margin` y `CornerRadius` del primer `Border` hijo
- El overlay respeta bordes redondeados y márgenes transparentes de la ventana

### Compilación y Release
- `WPF_Runner.exe` de 61KB con MsgBox + InputBox + botones redondeados
- `release/WPF_Runner.zip` actualizado

### Pendiente / A mejorar
- [ ] **Custom controls** — faltan `compile_WPF_Runner.bat` incluir referencias a DLLs de controles custom (ChartControl, OcrControl, etc.)

---

## Posibles Controles Futuros

### Prácticos (útiles en laburo)
- **Regex Tester** — expresión regular + texto de prueba con coloreado de matches y grupos en vivo
- **Job Queue Dashboard** — cola de tareas desde AHK con ejecución multi-thread, progress bar, cancelación
- **Serial / COM Port Monitor** — monitor de puerto serie con scroll hex+ASCII, baudrate configurable
- **Diff Viewer** — comparador de archivos side-by-side con diferencias coloreadas
- **Image Viewer** — visor con zoom, pan, rotación, fit-to-window
- **Property Grid** — editor genérico de pares clave=valor con tipos detectados automáticamente

### Creativos / Visuales
- **Fluid Simulation** — simulación Navier-Stokes en tiempo real con interacción mouse
- **Reaction-Diffusion** — patrones orgánicos (Gray-Scott) que evolucionan solos
- **Mandelbrot / Fractal Viewer** — zoom infinito con colores cíclicos
- **Glitch / Pixel Sort** — efectos de corrupción visual sobre imágenes
- **L-System Plants** — generación procedural de árboles/plantas fractales
- **ASCII Art** — conversión de imagen a arte ASCII en vivo

### No evaluados (requieren análisis)
- **Motion Detection** — detección de movimiento por cámara web (requiere DirectShowLib.NET) o cámara IP (MJPEG stream nativo). Mapeable a teclas/acciones vía AHK.
- **HTTP API Client** — peticiones REST/GraphQL desde WPF con visualización de respuesta formateada
- **Audio Visualizer** — espectro de audio en tiempo real con barras/olas
- **Mini IDE** — editor de código con syntax highlighting, line numbers, plegado

---

## Arquitectura Técnica

```
┌─────────────┐     WM_COPYDATA     ┌──────────────────┐
│  AHK 1.1    │ ◄──────────────────► │  WPF_Runner.exe  │
│             │    Base64/JSON       │  (.NET 4.x)      │
│ ui.Update() │                      │  XamlReader.Parse│
│ ui.OnEvent()│                      │  AhkControlBase  │
│ ui.Show()   │                      │  Controles hijos │
└─────────────┘                      └──────────────────┘
```

1. AHK crea ventana receptora oculta + hook WM_COPYDATA
2. AHK lanza `WPF_Runner.exe` con ruta del XAML, ID de instancia y HWND receptor
3. WPF_Runner parsea el XAML, crea la ventana y establece comunicación
4. `ui.Update()` → WM_COPYDATA → `SetProperty()` en el control WPF
5. Eventos WPF → `FireEvent()` → WM_COPYDATA → callback AHK
6. `GetAllState()` envía el estado completo de todos los controles en cada evento
