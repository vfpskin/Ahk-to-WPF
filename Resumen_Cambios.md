# Resumen de últimos cambios

## 1. `InputBox` — nuevo método modal

- **`XAMLGUI.ahk`**: método `InputBox(title, message, defaultText="")` que envía `_InputBox` a WPF y lee el resultado desde un archivo temporal
- **`Program_WPF.cs`**: comando especial `_InputBox` con `ShowInputBox()`, modal con TextBox, botones OK/Cancel, overlay oscuro, hereda el tema
- **`NewDemoAlert.ahk`**: reemplazado el overlay manual (`SweetInputOverlay`) por `ui.InputBox()`, ~36 líneas eliminadas

## 2. `MsgBox` con botones personalizados

- **`XAMLGUI.ahk`**: parámetro opcional `buttons` (ej: `"Yes|No|Cancel"`) en `Msgbox()`
- **`Program_WPF.cs`**: si se pasan botones, los crea dinámicamente; el retorno es 1, 2, 3... según la posición del botón presionado
- **`NewDemoAlert.ahk`**: botones "3 Buttons" y "4 Buttons" agregados al demo

## 3. Overlay corregido

- Cambiado de `root.Background` (se pintaba detrás del contenido opaco) a un `Border` con `ZIndex=500` agregado como hijo del root Grid
- `InferContentShape()` detecta automáticamente `Margin` y `CornerRadius` del primer Border hijo para que el overlay no invada bordes redondeados ni márgenes transparentes

## 4. Botones con `CornerRadius`

- Nuevo helper `MakeButtonStyle()` que crea un `ControlTemplate` con `Border` de `CornerRadius=8`
- Aplicado a todos los botones de MsgBox e InputBox

## 5. Ventanas más grandes

- `NewDemoAlert.xaml`: 640×680 para que entren todos los botones
- `ShowMsgBox()`: `MinWidth`/`MaxWidth` se calculan según la cantidad de botones para evitar botones cortados

## 6. Manual HTML actualizado

- Agregado panel de índice lateral izquierdo con anclas a cada sección
- Nuevas secciones **22. MsgBox** y **23. InputBox** con ejemplos de uso, tablas de valores de retorno y detalles técnicos
- Agregados `ui.Msgbox()` y `ui.InputBox()` a la tabla de métodos y a los pills del header
